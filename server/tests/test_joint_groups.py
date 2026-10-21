"""Tests for the joint groups the gui shows in the Monitoring page."""

import sys
from pathlib import Path

from urdf_parser_py import urdf as urdf_parser

SERVER_SRC = Path(__file__).parents[1] / 'src'
sys.path.insert(0, str(SERVER_SRC))

from xbot2_gui_server.joint_groups import joint_groups  # noqa: E402


def joint(name: str, parent: str, child: str) -> str:
    return (f'<joint name="{name}" type="revolute"><parent link="{parent}"/><child link="{child}"/>'
            '<limit lower="-1" upper="1" velocity="1" effort="1"/></joint>')


URDF = ('<robot name="r">' + ''.join(f'<link name="{n}"/>' for n in
        ['base_link', 'arm1_1', 'arm1_2', 'gripper_A_left', 'gripper_A_right', 'station_l', 'station_r', 'cam']) +
        joint('j_arm1_1', 'base_link', 'arm1_1') + joint('j_arm1_2', 'arm1_1', 'arm1_2') +
        joint('gripper_A_left_finger_joint', 'arm1_2', 'gripper_A_left') +
        joint('gripper_A_right_finger_joint', 'arm1_2', 'gripper_A_right') +
        joint('station_l_finger_j', 'base_link', 'station_l') + joint('station_r_finger_j', 'base_link', 'station_r') +
        joint('cam_joint', 'base_link', 'cam') + '</robot>')

SRDF = ('<robot name="r">'
        '<group name="arm"><chain base_link="base_link" tip_link="arm1_2"/></group>'
        '<group name="gripper_A"><joint name="gripper_A_left_finger_joint"/>'
        '<joint name="gripper_A_right_finger_joint"/></group>'
        '<group name="station"><joint name="station_l_finger_j"/><joint name="station_r_finger_j"/></group>'
        '<group name="station_left"><joint name="station_l_finger_j"/></group>'
        '</robot>')

JNAMES = ['j_arm1_1', 'j_arm1_2', 'gripper_A_left_finger_joint', 'gripper_A_right_finger_joint',
          'station_l_finger_j', 'station_r_finger_j', 'cam_joint']


def test_groups_follow_the_srdf() -> None:
    """Chains expand to their joints, contained groups are dropped, the rest goes to 'other'."""
    groups = joint_groups(SRDF, urdf_parser.Robot.from_xml_string(URDF), JNAMES)
    assert [(g['name'], g['joints']) for g in groups] == [
        ('arm', ['j_arm1_1', 'j_arm1_2']),
        ('gripper_A', ['gripper_A_left_finger_joint', 'gripper_A_right_finger_joint']),
        ('station', ['station_l_finger_j', 'station_r_finger_j']),
        ('other', ['cam_joint']),
    ]


def test_without_srdf_all_joints_are_one_group() -> None:
    groups = joint_groups(None, urdf_parser.Robot.from_xml_string(URDF), JNAMES)
    assert [g['name'] for g in groups] == ['joints']
    assert groups[0]['joints'] == JNAMES
