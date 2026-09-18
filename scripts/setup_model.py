
"""
Cross-platform first-run model setup for Writ.

- Detects an existing Ollama install and the Vidhi LLM (hf.co/prawinin/vidhi).
- Answers "where is the model stored?" (OLLAMA_MODELS / ~/.ollama / %USERPROFILE%/.ollama).
- Pulls hf.co/prawinin/vidhi (~2 GB) if missing.
- Used by the Windows/macOS/Linux installers AND by users manually:
      python scripts/setup_model.py [--pull] [--quiet]

Exit codes: 0 = model ready, 1 = ollama missing, 2 = pull failed/incomplete.
"""
import json 
import os 
import shutil 
import subprocess 
import sys 
import urllib .request 

MODEL ="hf.co/prawinin/vidhi"
PULL_URL ="http://localhost:11434/api/pull"
TAGS_URL ="http://localhost:11434/api/tags"


def default_model_dir ():
    env =os .environ .get ("OLLAMA_MODELS","")
    if env :
        return env +"  (from OLLAMA_MODELS)"
    home =os .path .expanduser ("~")
    if sys .platform =="win32":
        return os .path .join (home ,".ollama","models")
    return os .path .join (home ,".ollama","models")


def ollama_bin ():
    return shutil .which ("ollama")


def ollama_running ():
    try :
        with urllib .request .urlopen (TAGS_URL ,timeout =4 )as r :
            return json .loads (r .read ().decode ())
    except Exception :
        return None 


def model_installed (tags ):
    names =[m .get ("name","")for m in tags .get ("models",[])]
    return MODEL in names or f"{MODEL }:latest"in names 


def pull_model ():

    if ollama_bin ():
        print (f"Pulling {MODEL } (~2 GB, one-time download)...")
        rc =subprocess .run (["ollama","pull",MODEL ]).returncode 
        return rc ==0 
    try :
        req =urllib .request .Request (
        PULL_URL ,data =json .dumps ({"name":MODEL ,"stream":False }).encode (),
        headers ={"Content-Type":"application/json"})
        with urllib .request .urlopen (req ,timeout =3600 ):
            return True 
    except Exception as e :
        print (f"Pull failed: {e }",file =sys .stderr )
        return False 


def main ():
    quiet ="--quiet"in sys .argv 
    log =(lambda *a :None )if quiet else print 
    log (f"Model storage location: {default_model_dir ()}")

    if not ollama_bin ():
        log ("Ollama is NOT installed. Install it first: https://ollama.com")
        log ("  Windows/macOS: run the OllamaSetup / Ollama.app installer.")
        log ("  Linux: curl -fsSL https://ollama.com/install.sh | sh")
        return 1 

    tags =ollama_running ()
    if tags is None :
        log ("Ollama is installed but not running. Starting it...")
        try :
            if sys .platform =="win32":
                subprocess .Popen (["ollama","serve"],
                creationflags =subprocess .DETACHED_PROCESS )
            else :
                subprocess .Popen (["ollama","serve"],
                stdout =subprocess .DEVNULL ,stderr =subprocess .DEVNULL )
        except Exception as e :
            log (f"Could not start ollama: {e }")
            return 1 
        import time 
        for _ in range (15 ):
            time .sleep (2 )
            tags =ollama_running ()
            if tags is not None :
                break 
        if tags is None :
            log ("Ollama still not responding. Start it manually, then re-run.")
            return 1 

    if model_installed (tags ):
        log (f"Model {MODEL } already downloaded at: {default_model_dir ()}")
        log ("Nothing to download.")
        return 0 

    log (f"Model {MODEL } not found locally.")
    if "--pull"in sys .argv or "--yes"in sys .argv :
        ok =pull_model ()
    else :
        try :
            ans =input (f"Download {MODEL } now (~2 GB)? [Y/n] ").strip ().lower ()
        except EOFError :
            ans ="y"
        ok =pull_model ()if ans in ("","y","yes")else False 
    if not ok :
        log ("Model download did not complete. Re-run: python scripts/setup_model.py --pull")
        return 2 
    log ("Model ready.")
    return 0 


if __name__ =="__main__":
    sys .exit (main ())
