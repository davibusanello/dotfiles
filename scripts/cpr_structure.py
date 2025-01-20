import os
import argparse

def replicate_structure(src, dest):
    # Create the destination directory
    if not os.path.exists(dest):
        os.makedirs(dest)

    # Walk through the directory structure
    for dirpath, dirnames, filenames in os.walk(src):
        # Construct the path structure in the destination
        for dirname in dirnames:
            # Calculate relative path, then construct full destination path
            rel_path = os.path.relpath(os.path.join(dirpath, dirname), src)
            dest_path = os.path.join(dest, rel_path)

            if not os.path.exists(dest_path):
                os.makedirs(dest_path)

def main():
    parser = argparse.ArgumentParser(description="Replicate Directory Structure")
    parser.add_argument('source', help='Source directory path')
    parser.add_argument('destination', help='Destination directory path')
    args = parser.parse_args()

    replicate_structure(args.source, args.destination)
    print(f"Structure from {args.source} has been replicated to {args.destination}.")

if __name__ == "__main__":
    main()
