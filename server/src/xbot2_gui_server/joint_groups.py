import xml.etree.ElementTree as ET


def joint_groups(srdf: str | None, model, jnames: list[str]) -> list[dict]:
    """Group the joints in jnames by the SRDF groups, for the GUI.

    srdf: SRDF xml, or None; model: urdf_parser_py Robot, used to expand the chains.
    Returns [{'name', 'joints': [joint names]}], in SRDF order. A group contained in another is
    dropped, each joint goes to the first group that has it, the rest to 'other'.
    """
    groups = []
    for g in ET.fromstring(srdf).iter('group') if srdf else []:
        joints = [j.get('name') for j in g.iter('joint')]
        for c in g.iter('chain'):
            joints += model.get_chain(c.get('base_link'), c.get('tip_link'), links=False, fixed=False)
        joints = [j for j in jnames if j in joints]
        if joints:
            groups.append((g.get('name'), joints))

    # drop duplicates and groups contained in another
    groups = [(n, js) for i, (n, js) in enumerate(groups)
              if not any(set(js) <= set(other) and (len(js) < len(other) or k < i)
                         for k, (_, other) in enumerate(groups) if k != i)]

    taken = set()
    out = []
    for name, joints in groups + [('other' if groups else 'joints', jnames)]:
        joints = [j for j in joints if j not in taken]
        if joints:
            taken.update(joints)
            out.append({'name': name, 'joints': joints})
    return out
