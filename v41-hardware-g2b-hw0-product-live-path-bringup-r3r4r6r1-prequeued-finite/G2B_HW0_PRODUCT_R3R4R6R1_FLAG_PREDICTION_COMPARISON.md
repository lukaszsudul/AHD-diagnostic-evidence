
# Flag Prediction Comparison

- Frozen prediction: `RECORDED_BEFORE_RUN`
- First-record prediction: `NOT_REACHED`
- Post-first-record prediction: `NOT_REACHED`
- Clean-frame prediction: `NOT_REACHED`

The short primary completion was not persisted by the still-running native
helper, so no record bytes were inspected and the prediction was not revised.
