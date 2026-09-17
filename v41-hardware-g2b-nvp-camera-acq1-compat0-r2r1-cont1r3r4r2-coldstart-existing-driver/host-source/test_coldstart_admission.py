"""Synthetic offline tests of pure cold-start admission only."""

from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path


PAYLOAD = Path(__file__).resolve().parents[1] / "runtime-bundle" / "payload"
sys.path.insert(0, str(PAYLOAD))
from coldstart_admission import admit_postboot, scan_receipt_valid, select_target_nodes  # noqa: E402


def state():
    return {"phase": "POST_COLD_ADMISSION_IN_PROGRESS",
            "owner_attestation_token": "DUT_COLD_START_COMPLETE",
            "owner_attested_cold_cycles": 1,
            "programming_attempts": 0,
            "pre_cold_boot_id": "old-boot"}


def survey():
    return {"endpoint": "10.132.1.111:22",
            "host_key": "SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8",
            "hostname": "VCDE-DUT-1",
            "machine_id": "0e90f50d9465492b80258da5658446f8",
            "boot_id": "new-boot", "xdma_class_exists": False,
            "foreign_xdma_loaded": False, "known_pending_loader": False,
            "project_lock_conflict": False, "active_competing_task": False,
            "readiness_complete": True, "pci": []}


def target():
    return {"bdf": "0000:31:00.0", "vendor": "0x10ee", "device": "0x7011",
            "subsystem_vendor": "0x10ee", "subsystem_device": "0x0007",
            "modalias": "pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00",
            "driver": None}


def node(role, index=3, bdf="0000:31:00.0", boot="new-boot"):
    return {"path": f"/dev/xdma{index}_{role}", "role": role, "index": index,
            "nearest_pci": bdf, "boot_id": boot,
            "driver_module": "xdma_ahd_pcie", "is_character": True,
            "major_minor": "511:0" if role == "user" else "511:36",
            "sysfs_dev_t": "511:0" if role == "user" else "511:36"}


class ColdstartAdmissionTests(unittest.TestCase):
    def test_t1_no_action_before_gate(self):
        s = state(); s["phase"] = "WAITING_OWNER_COLD_START"
        self.assertEqual(admit_postboot(s, survey())["result"], "BLOCKED")

    def test_t2_duplicate_owner_token_consumes_no_second_cycle(self):
        s = state(); s["owner_attested_cold_cycles"] = 2
        self.assertEqual(admit_postboot(s, survey())["result"], "BLOCKED")

    def test_t3_new_boot_allowed_same_boot_not_proof(self):
        self.assertEqual(admit_postboot(state(), survey())["result"], "READ_ONLY_JTAG_REQUIRED")
        q = survey(); q["boot_id"] = "old-boot"
        self.assertEqual(admit_postboot(state(), q)["result"], "BLOCKED")

    def test_t4_wrong_host_key_or_identity_stops(self):
        for key, value in (("host_key", "wrong"), ("hostname", "wrong"),
                           ("machine_id", "wrong"), ("endpoint", "192.168.1.57:22")):
            q = survey(); q[key] = value
            self.assertEqual(admit_postboot(state(), q)["reason"], "DUT_IDENTITY_CONTRADICTION")

    def test_t5_foreign_class_blocks_even_if_another_index_exists(self):
        q = survey(); q["xdma_class_exists"] = True; q["pci"] = [target()]
        self.assertEqual(admit_postboot(state(), q)["reason"],
                         "CLASS_COLLISION_RECREATED_AFTER_ONE_COLD_START")

    def test_t6_pending_loader_is_not_race_to_load(self):
        q = survey(); q["known_pending_loader"] = True
        self.assertEqual(admit_postboot(state(), q)["reason"], "PENDING_FOREIGN_LOADER_RACE")

    def test_t7_wrong_bdf_role_or_dev_t_rejected(self):
        variants = ([node("user", bdf="0000:0b:00.0"), node("c2h_0")],
                    [node("user"), node("user")],
                    [dict(node("user"), sysfs_dev_t="511:99"), node("c2h_0")])
        for pair in variants:
            with self.assertRaises(ValueError):
                select_target_nodes(pair, "0000:31:00.0", "new-boot")

    def test_t8_dynamic_index_explicit_user_path(self):
        got = select_target_nodes([node("user"), node("c2h_0")], "0000:31:00.0", "new-boot")
        self.assertEqual(got["user"], "/dev/xdma3_user")
        self.assertEqual(got["c2h_0"], "/dev/xdma3_c2h_0")

    def test_t9_preboot_node_name_cannot_cross_boot(self):
        with self.assertRaises(ValueError):
            select_target_nodes([node("user", boot="old-boot"),
                                 node("c2h_0", boot="old-boot")], "0000:31:00.0", "new-boot")

    def test_t10_recovered_nack_no_event_count_cap_hard_errors_stop(self):
        r = {"complete": True, "coherent": True, "entry_bank_restored": True,
             "telemetry_complete": True, "entries": 82, "groups": 10,
             "retried_entry_count": 5, "transactions": 110, "hard_error": False}
        self.assertTrue(scan_receipt_valid(r))
        bad = copy.deepcopy(r); bad["hard_error"] = True
        self.assertFalse(scan_receipt_valid(bad))
        bad = copy.deepcopy(r); bad["telemetry_complete"] = False
        self.assertFalse(scan_receipt_valid(bad))


if __name__ == "__main__":
    unittest.main(verbosity=2)
