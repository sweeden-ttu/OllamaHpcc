import os
import requests
import subprocess
from typing import List, Dict, Optional, Any


class OllamaServer:
    """Manages Ollama server instances on HPCC or local."""

    PORTS = {"granite": 55077, "think": 55088, "qwen": 66044, "code": 66033}

    MODELS = {
        "granite": "granite4",
        "think": "deepseek-r1",
        "qwen": "qwen2.5-coder",
        "code": "codellama",
    }

    def __init__(self, host: str = "localhost"):
        self.host = host
        self.base_url = f"http://{host}"

    def check_health(self, port: int) -> bool:
        """Check if Ollama is running on port."""
        try:
            resp = requests.get(f"{self.base_url}:{port}/api/tags", timeout=2)
            return resp.status_code == 200
        except:
            return False

    def list_models(self, port: int) -> List[str]:
        """List available models on a port."""
        try:
            resp = requests.get(f"{self.base_url}:{port}/api/tags", timeout=5)
            if resp.status_code == 200:
                return [m["name"] for m in resp.json().get("models", [])]
        except:
            pass
        return []

    def generate(self, model_type: str, prompt: str, **kwargs) -> Optional[str]:
        """Generate text with specified model."""
        port = self.PORTS.get(model_type)
        model = self.MODELS.get(model_type)
        if not port or not model:
            return None

        try:
            resp = requests.post(
                f"{self.base_url}:{port}/api/generate",
                json={"model": model, "prompt": prompt, **kwargs},
                timeout=120,
            )
            if resp.status_code == 200:
                return resp.json().get("response", "")
        except Exception as e:
            print(f"Error: {e}")
        return None

    def chat(self, model_type: str, messages: List[Dict[str, str]]) -> Optional[str]:
        """Chat with specified model."""
        port = self.PORTS.get(model_type)
        model = self.MODELS.get(model_type)
        if not port or not model:
            return None

        try:
            resp = requests.post(
                f"{self.base_url}:{port}/api/chat",
                json={"model": model, "messages": messages},
                timeout=120,
            )
            if resp.status_code == 200:
                return resp.json().get("message", {}).get("content", "")
        except Exception as e:
            print(f"Error: {e}")
        return None

    def start_local(
        self, model_type: str, container_name: Optional[str] = None
    ) -> bool:
        """Start local Ollama container."""
        port = self.PORTS.get(model_type)
        model = self.MODELS.get(model_type)
        if not port or not model:
            return False

        name = container_name or f"ollama-{model_type}"

        try:
            subprocess.run(
                [
                    "podman",
                    "run",
                    "-d",
                    "--name",
                    name,
                    "-p",
                    f"{port}:{port}",
                    "-v",
                    "ollama:/root/.ollama",
                    "-e",
                    f"OLLAMA_HOST=0.0.0.0:{port}",
                    "quay.io/ollama/ollama",
                    "serve",
                ],
                check=True,
            )
            subprocess.run(
                ["podman", "exec", name, "ollama", "pull", model], check=True
            )
            return True
        except:
            return False

    def get_status(self) -> Dict[str, Any]:
        """Get status of all Ollama servers."""
        status = {}
        for name, port in self.PORTS.items():
            health = self.check_health(port)
            models = self.list_models(port) if health else []
            status[name] = {
                "port": port,
                "model": self.MODELS[name],
                "healthy": health,
                "models": models,
            }
        return status


class OllamaClient:
    """LangChain-compatible Ollama client wrapper."""

    def __init__(self, model_type: str, host: str = "localhost"):
        self.server = OllamaServer(host=host)
        self.model_type = model_type
        self.model = self.server.MODELS.get(model_type)
        self.port = self.server.PORTS.get(model_type)

    def invoke(self, prompt: str) -> str:
        """Generate text from prompt."""
        result = self.server.generate(self.model_type, prompt)
        return result if result else ""

    def chat(self, messages: List[Dict[str, str]]) -> str:
        """Chat with messages."""
        result = self.server.chat(self.model_type, messages)
        return result if result else ""

    @property
    def llm(self):
        """Return LangChain-compatible LLM."""
        try:
            from langchain_community.llms import Ollama as LCOllama

            return LCOllama(
                model=self.model, base_url=f"http://{self.server.host}:{self.port}"
            )
        except ImportError:
            return None
