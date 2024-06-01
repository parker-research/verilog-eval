from pathlib import Path
import json


def extract_dataset_to_files() -> None:
    """Repairs the invalid Verilog tests in the VerilogEval_Human dataset.
    Writes the fixed dataset to a new file (<repo_root>/data/VerilogEval_Human_fixed.jsonl).
    Also writes the original and modified Verilog files to the working directory for review.

    This repair was done to the VerilogEval_Human dataset @ commit 4b9b16e.

    All tests are invalid because they use the "tb_mismatch" wire before it is declared.
    This was valid in old versions of IVerilog, but is no longer valid in the current version.
    """
    repo_root = Path(__file__).parent.parent
    output_folder = repo_root / "problems"

    source_files = [
        repo_root / "data" / "VerilogEval_Human.jsonl",
        repo_root / "descriptions" / "VerilogDescription_Human.jsonl",
    ]

    for source_file in source_files:
        with open(source_file, "r") as f:
            for line in f:
                data = json.loads(line)

                problem_folder = output_folder / data["task_id"]
                problem_folder.mkdir(exist_ok=True, parents=True)

                for key in list(set(data.keys()) - {"task_id"}):
                    with open(problem_folder / f"{key}.sv", "w") as f:
                        f.write(data[key])

                        if not data[key].endswith("\n"):
                            f.write("\n")


if __name__ == "__main__":
    extract_dataset_to_files()
