Admits the VM owner through the exe.dev proxy and tells the agent how to use this exe.dev VM.

- Access: allows `ULTIMATE_EXE_ORIGIN` (from `ultimate-start`) when `x-exedev-email` equals `ULTIMATE_EXE_OWNER` and `x-exedev-userid` is set.
- Prompt: an `exedev` section pointing at the reflection endpoint (`https://reflection.int.exe.xyz/`, `/integrations`), `ssh exe.dev` and the exe.dev docs.
