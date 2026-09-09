
# Prior black-frame classification

The inherited FIX1-R1 frame sequence 8129, epoch 2, records 761..1840 was a
complete real 1920x1080 frame with no synthetic lines, but its raw frame SHA-256
was `3B189674E4CBA4542AF800037704EF3A5DABAD5ACF43285C19082AB776B246B0` and every UYVY group was `80 10 80 10`. PNG conversion was
not the cause. The fresh baseline is an independent comparison and reaches the
same exact-black hash.
