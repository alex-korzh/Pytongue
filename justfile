# set PYTONGUE_LOG there
set dotenv-load

build:
    zig build
run:
    zig build run
test:
    poetry run pytest tests/e2e


retest: build test