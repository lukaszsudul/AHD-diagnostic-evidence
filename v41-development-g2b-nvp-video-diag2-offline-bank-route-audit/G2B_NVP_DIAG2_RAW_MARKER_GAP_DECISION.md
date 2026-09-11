
# Raw-marker observability gap

R3 exposes VCLK and a direct post-frontend legal raw SAV counter. It does not expose raw byte-change activity, FF/FF00/FF0000 prefix counts, all FF0000XY candidates, legal EAV, or illegal-XY/parity counts. Parser lock and aggregate malformed/length/drop outcomes exist, while parser state is only indirectly visible.

Existing R3 observability is INSUFFICIENT to distinguish constant VDO, changing non-marker data, invalid marker prefixes/parity, and legal EAV/SAV admission. A minimal raw-marker diagnostic extension is required.
