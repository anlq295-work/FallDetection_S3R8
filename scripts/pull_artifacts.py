import os
import subprocess
import urllib.request
import zipfile
import shutil
import json

def get_github_token():
    try:
        proc = subprocess.run(
            ["git", "credential", "fill"],
            input=b"protocol=https\nhost=github.com\n",
            capture_output=True,
            check=True
        )
        lines = proc.stdout.decode().splitlines()
        for line in lines:
            if line.startswith("password="):
                return line.split("=", 1)[1].strip()
    except Exception as e:
        print(f"Error getting git credential: {e}")
    return os.environ.get("GITHUB_TOKEN", "")

class CustomRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        new_req = super().redirect_request(req, fp, code, msg, headers, newurl)
        if new_req and "blob.core.windows.net" in newurl:
            for k in list(new_req.headers.keys()):
                if k.lower() == "authorization":
                    del new_req.headers[k]
        return new_req

def download_artifact(artifact_id, out_zip_path, token):
    url = f"https://api.github.com/repos/anlq295-work/FallDetection_S3R8/actions/artifacts/{artifact_id}/zip"
    headers = {
        "User-Agent": "FallGuard-Puller",
        "Authorization": f"Bearer {token}"
    }
    req = urllib.request.Request(url, headers=headers)
    opener = urllib.request.build_opener(CustomRedirect)
    print(f"--> Downloading artifact {artifact_id}...")
    with opener.open(req) as resp, open(out_zip_path, "wb") as f:
        shutil.copyfileobj(resp, f)
    print(f"    Downloaded successfully: {out_zip_path} ({os.path.getsize(out_zip_path)} bytes)")

def main():
    token = get_github_token()
    if not token:
        print("GitHub token not found!")
        return

    # Lay run moi nhat
    runs_url = "https://api.github.com/repos/anlq295-work/FallDetection_S3R8/actions/runs?per_page=1"
    req = urllib.request.Request(runs_url, headers={"User-Agent": "FallGuard-Puller", "Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode())
    
    latest_run = data["workflow_runs"][0]
    run_id = latest_run["id"]
    print(f"Latest run: #{run_id} (Status: {latest_run['status']}, Conclusion: {latest_run['conclusion']})")

    # Lay danh sach artifacts
    art_url = f"https://api.github.com/repos/anlq295-work/FallDetection_S3R8/actions/runs/{run_id}/artifacts"
    req_art = urllib.request.Request(art_url, headers={"User-Agent": "FallGuard-Puller", "Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req_art) as resp:
        art_data = json.loads(resp.read().decode())

    os.makedirs("downloaded_artifacts", exist_ok=True)
    artifacts_dir = r"C:\Users\Admin\.gemini\antigravity\brain\27ff834c-fae6-4ffd-9f36-3f32a9608f7e"

    for art in art_data.get("artifacts", []):
        name = art["name"]
        art_id = art["id"]
        zip_path = os.path.join("downloaded_artifacts", f"{name}.zip")
        download_artifact(art_id, zip_path, token)

        # Giai nen file
        extract_dir = os.path.join("downloaded_artifacts", name)
        os.makedirs(extract_dir, exist_ok=True)
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_dir)
            extracted_files = zip_ref.namelist()
            print(f"    Extracted files from {name}: {extracted_files}")
            
            for file_name in extracted_files:
                src_path = os.path.join(extract_dir, file_name)
                # Sao chep ra thu muc goc
                dest_root = os.path.join(".", file_name)
                shutil.copy2(src_path, dest_root)
                print(f"    => Copied to root workspace: {os.path.abspath(dest_root)}")
                # Sao chep vao Artifacts thu muc cua Antigravity
                if os.path.exists(artifacts_dir):
                    dest_artifact = os.path.join(artifacts_dir, file_name)
                    shutil.copy2(src_path, dest_artifact)
                    print(f"    => Copied to Antigravity Artifacts: {dest_artifact}")

    print("\nSUCCESS: Both APK and IPA have been automatically pulled to your computer!")

if __name__ == "__main__":
    main()
