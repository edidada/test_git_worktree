"""计费模块骨架（工位 B 独立提交）。"""

TAX_RATE = 0.06


def total(amount: float) -> float:
    return round(amount * (1 + TAX_RATE), 2)
