"""Tests for the extensions listed in the server config file."""

import sys
from pathlib import Path


SERVER_SRC = Path(__file__).parents[1] / 'src'
sys.path.insert(0, str(SERVER_SRC))

from xbot2_gui_server.main import extra_extensions  # noqa: E402


def test_config_entries_become_module_class_pairs() -> None:
    """Each [module, class] entry becomes a (module, class) pair, in config order."""
    cfg = {'extensions': [['my_pkg.mission', 'MissionHandler'], ['my_pkg.env', 'EnvHandler']]}
    assert extra_extensions(cfg) == [
        ('my_pkg.mission', 'MissionHandler'),
        ('my_pkg.env', 'EnvHandler'),
    ]


def test_missing_or_empty_key_adds_nothing() -> None:
    """Configs without extensions keep only the built-in ones."""
    assert extra_extensions({}) == []
    assert extra_extensions({'extensions': None}) == []
