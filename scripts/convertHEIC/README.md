# heic-convert

A simple bash script to recursively convert HEIC images to JPG.

## Dependencies

- `libheif´


## Usage

```bash
bash heic-convert.sh <path>
```

**Example:**

```bash
bash heic-convert.sh "/path/to/your/photos"
```

## How it works

The script uses `find` to recursively locate all `.heic` and `.HEIC` files under the given path, converts each one to JPG using `heif-convert`, and deletes the original only if the conversion succeeds.

Since originals are deleted after conversion, re-running the script on the same folder is safe — already converted files are simply ignored.

## Installation (optional)

To use the script from anywhere on your system:

```bash
chmod +x heic-convert.sh
sudo mv heic-convert.sh /usr/local/bin/heic-convert
```

Then run it as:

```bash
heic-convert "/path/to/your/photos"
```
