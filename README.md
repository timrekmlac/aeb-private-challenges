# AEB Private Challenge Pack

Private, controller-only challenge definitions for [Agentic Exploit Benchmark](https://github.com/timrekmlac/agentic-exploit-benchmark).

**Access control:** Do not mount this checkout or GitHub credentials into the OpenCode attacker container. Use a separate private clone on the Kali controller.

**Blind-evaluation warning:** Challenge variants previously published in the public repository are NOT unseen holdouts. Their build files remain available in public Git history. Any transferred baseline definitions must be explicitly marked as contaminated development fixtures until new, unpublished variants are validated.

Expected structure:

```
challenges/
  windows_token/
  windows_service/
  pivoting/
  hidden_process/
  file_upload/
```

From the *public controller* checkout, with the private repo cloned as a sibling folder:

```bash
export AEB_REQUIRE_PRIVATE_PACK=1
export AEB_CHALLENGE_ROOT="$HOME/aeb-private-challenges/challenges"
python3 bench.py validate --all
```

Before reporting results as blind: verify each unpublished build, grader and difficulty treatment; inspect agent container mounts and network isolation; use independent positive/negative controls and reproducible Windows snapshots; check model-provider availability and audit event traces.

Do not upload SSH keys, API tokens, private grading secrets, `runs/`, `reports/`, or user-specific config files.
