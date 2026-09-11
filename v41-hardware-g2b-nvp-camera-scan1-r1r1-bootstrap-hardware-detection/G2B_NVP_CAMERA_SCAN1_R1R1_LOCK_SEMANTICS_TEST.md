
# Lock semantics test

The task-local atomic lock probe passed: first `mkdir` succeeded, the second `mkdir` failed as required, metadata write/read passed, and the disposable probe was removed. The real controller and DUT locks were then acquired for the same task identity. No parallel hardware activity was observed.
