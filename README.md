#### A simple command-line tool to host images on ImgBB.



### Prerequisites
Make sure you have the following dependencies installed:
- `curl`
- `jq`
- `bc`

### Installation
1. **Download the Script:**
    ```bash
    sudo curl -o /usr/local/bin/imgbb https://raw.githubusercontent.com/shmVirus/imgbb/main/imgbb.sh
    ```
2. **Give Execute Permissions:**
    ```bash
    sudo chmod +x /usr/local/bin/imgbb
    ```
3. **Set up ImgBB API key:**
   - Obtain your ImgBB API key from [ImgBB Account Settings](https://api.imgbb.com/).
   - Set the API key as an environment variable:
        ```bash
        export IMGBB_API_KEY="your_api_key_here"
        ```
## Features
- Upload one or more images to ImgBB from the command line.
- Set expiration time for images (default: 10 minutes, 0 for account default).
- Displays Viewer, Direct, Medium, Thumb, and Delete URLs for each uploaded image.

## Usage
```bash
imgbb file1 ... fileN [-e <expiration_time>]

Options:
   -e <expiration_time>   Set expiration time in minutes
                          default: 10, use 0 for account default
   -h, --help             Display this help message

Shows: Viewer, Direct, Medium, Thumb, Delete URLs
