# Loaded when the cell boots, before any operation.
#
# deadline and queue_wait are seconds; memory and file_size are bytes.
HotCell.limits concurrency: 2, queue_size: 8, queue_wait: 5, deadline: 20, memory: 1280 * 1024**2
ENV["VIPS_DISC_THRESHOLD"] = "1g"
