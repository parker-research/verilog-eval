from pathlib import Path
import json
import re

import git


def get_repo_root() -> Path:
    repo = git.Repo(__file__, search_parent_directories=True)
    return Path(repo.working_tree_dir)

def get_working_dir() -> Path:
    repo_root = get_repo_root()
    (working_dir := repo_root / "working_dir").mkdir(exist_ok=True)
    return working_dir


def modify_verilog_file(verilog_content: str, prompt_id: str = "?") -> str:
    print(f"Modifying verilog content for prompt {prompt_id}")
    # Pattern to match the initial begin ... end block
    initial_pattern = re.compile(
        r"(\s*initial\s+begin\s+\$dumpfile\([^;]+;\s+\$dumpvars\([^;]+;\s+end\s*)",
        flags=re.DOTALL
    )
    
    # Pattern to match the wire declarations for tb_match and tb_mismatch
    wire_pattern = re.compile(
        r"(\s*wire\s+tb_match;.*\s+wire\s+tb_mismatch[^;]+;\s*)",
        flags=re.DOTALL
    )
    
    # Find the blocks using regex
    initial_block = initial_pattern.search(verilog_content)
    wire_block = wire_pattern.search(verilog_content)
    
    # If both blocks are found, perform the swap
    if initial_block and wire_block:
        # Extract the match blocks
        initial_text = initial_block.group(1)
        wire_text = wire_block.group(1)
        
        # Remove original blocks from content
        modified_content = initial_pattern.sub("", verilog_content)
        modified_content = wire_pattern.sub("", modified_content)
        
        # Find where the initial block started
        initial_start_index = initial_block.start()
        
        # Insert the wire block just before the initial block
        modified_content = (modified_content[:initial_start_index] + 
                            wire_text + "\n" + 
                            initial_text + 
                            modified_content[initial_start_index:])
        
        return modified_content
    
    elif initial_block is None and wire_block is None:
        raise Exception(f"In {prompt_id}, could not find 'initial' AND 'wire' block in verilog content")
    elif initial_block is None:
        raise Exception(f"In {prompt_id}, could not find 'initial block' in verilog content")
    elif wire_block is None:
        raise Exception(f"In {prompt_id}, could not find 'wire block' in verilog content")
    else:
        raise Exception("This should not happen")
    
    # Return the original if any block is missing (fail-safe)
    return verilog_content


def modify_invalid_verilog_tests() -> None:
    """Repairs the invalid Verilog tests in the VerilogEval_Human dataset.
    Writes the fixed dataset to a new file (<repo_root>/data/VerilogEval_Human_fixed.jsonl).
    Also writes the original and modified Verilog files to the working directory for review.

    This repair was done to the VerilogEval_Human dataset @ commit 4b9b16e.

    All tests are invalid because they use the "tb_mismatch" wire before it is declared.
    This was valid in old versions of IVerilog, but is no longer valid in the current version.
    """
    source_file = get_repo_root() / 'data/VerilogEval_Human.jsonl'
    dest_file = get_repo_root() / 'data/VerilogEval_Human_fixed.jsonl'

    if dest_file.exists():
        print(f"Destination file {dest_file} already exists, deleting it")
        dest_file.unlink()

    with open(source_file, 'r') as f:
        for line in f:
            data = json.loads(line)
            
            (unpack_dir := get_working_dir() / 'data' / data["task_id"]).mkdir(exist_ok=True, parents=True)

            for key in ["prompt", "canonical_solution", "test"]:
                with open(unpack_dir / f"{key}.orig.sv", 'w') as f:
                    f.write(data[key])

            modified_test = modify_verilog_file(data["test"], data["task_id"])
            with open(unpack_dir / f"test.mod.sv", 'w') as f:
                f.write(modified_test)

            # overwrite the current test value with the modified one
            data["test"] = modified_test
            with open(dest_file, 'a') as f:
                json.dump(data, f)
                f.write('\n')


if __name__ == "__main__":
    modify_invalid_verilog_tests()
