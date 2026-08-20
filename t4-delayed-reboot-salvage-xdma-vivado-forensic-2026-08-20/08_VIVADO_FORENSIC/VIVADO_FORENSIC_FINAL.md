# Vivado forensic final

The exact Vivado 2025.2 root, settings script, batch launcher, internal executable, and signed/readable `xv_common.dll` were found. The ordinary Codex process had no Vivado path/environment. A controlled non-GUI launch through `settings64.bat` and `vivado.bat -version` passed and reported Vivado 2025.2.

Together with the preserved direct internal-executable launch path, this supports a missing launcher environment rather than a missing/corrupt DLL installation.

    CONTROLLED_VIVADO_VERSION_LAUNCH=PASS_VIVADO_2025_2
    VIVADO_FORENSIC_CLASSIFICATION=VIVADO_CONTROLLED_LAUNCH_PASS_ROOT_CAUSE_LIKELY_BAD_LAUNCHER
    VIVADO_ERROR_IS_NVP_RESULT=NO
    VIVADO_ERROR_INVALIDATES_RECORDED_EOS_DONE=NO

