"""最小示例应用：让各 worktree 分支产生真实的 diff。"""

VERSION = "1.0.0"


def greet(name: str) -> str:
    return f"Hello, {name}!"


if __name__ == "__main__":
    print(f"app {VERSION}: {greet('worktree')}")
