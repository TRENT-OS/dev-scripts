#!/usr/bin/env python3
#-------------------------------------------------------------------------------
#
# Git Repo Manager
#
#
# required packages: python3-git, python3-gitdb
#
#-------------------------------------------------------------------------------

import os, sys, platform
import argparse
import git

#-------------------------------------------------------------------------------
def branch_info_str(branch):
    return "[{}]@{}".format(branch.name, branch.commit.hexsha[:8])


#-------------------------------------------------------------------------------
def add_branch_to_dict(d, branch):
    commit = branch.commit
    if not commit in d:
        d[commit] = []
    d[commit].append(branch)


#-------------------------------------------------------------------------------
def group_branches_by_commit(branch_list):
    d = {}
    for branch in branch_list:
        add_branch_to_dict(d, branch)

    return d


#-------------------------------------------------------------------------------
def branches_info_str(branch_list):
    d = group_branches_by_commit(branch_list)
    return ", ".join([
                    "[{}]@{}".format(
                        ", ".join(branch.name for branch in branches),
                        commit.hexsha[:8] )
                    for commit, branches in d.items() ] )


#-------------------------------------------------------------------------------
def get_commit_delta_str(cnt, branch_list):

    # branch_list is supposed to have branches for one commit only, so there
    # is no need to call branches_info_str() to print then. We can just print
    # the list.
    return "{} {}".format(
                "at" if (0 == cnt) \
                    else "{} commit{} {}".format(
                            abs(cnt),
                            "s" if (abs(cnt) > 1) else "",
                            "ahead of" if (cnt > 0) else "behind"),
                ", ".join(branch.name for branch in branch_list))


#-------------------------------------------------------------------------------
def get_repo_info(repo):

    head = repo.head
    commit = head.commit

    branch_or_detached = "(detached)" if head.is_detached \
                         else "[{}]".format(repo.active_branch.name)

    #tag_dirty_clean = "[{}]".format("dirty" if repo.is_dirty() else "clean")
    tag_dirty_clean = " [dirty]" if repo.is_dirty() else ""


    return commit.hexsha[:8] + \
            " " + branch_or_detached + \
            tag_dirty_clean + \
            " \"" + commit.summary + "\""


#-------------------------------------------------------------------------------
def get_filtered_branch_list(branch_list, filter_list):
    return list( filter(
                    lambda branch: branch.name in filter_list,
                    branch_list) )

#-------------------------------------------------------------------------------
def get_branches(repo, branch_filter = None):

    head_commit = repo.head.commit

    is_same = list()
    is_ancestor = dict()
    is_child = dict()
    is_unrelated = dict()

    for branches in (repo.heads, repo.remote().refs):
        for branch in branches:
            #print(branch.name)

            if branch_filter and (not branch.name in branch_filter):
                continue
            branch_commit = branch.commit

            if (branch_commit == head_commit):
                is_same.append(branch)

            elif repo.is_ancestor(branch_commit, head_commit):
                # delta = get_ancestor_delta(head_commit, branch_commit)
                add_branch_to_dict(is_ancestor, branch)

            elif repo.is_ancestor(head_commit, branch_commit):
                # delta = -get_ancestor_delta(branch_commit, head_commit)
                add_branch_to_dict(is_child, branch)

            else:
                add_branch_to_dict(is_unrelated, branch)

    return (is_same, is_ancestor, is_child, is_unrelated)


#-------------------------------------------------------------------------------
def get_ancestor_delta(
    commit,
    branch_head_commit,
    distance = 0,
    dead_ends = None,
    seen_commits = None,
    my_path = None ):

    if dead_ends is None:
        dead_ends = []
    elif commit in dead_ends:
        return -1

    if seen_commits is None:
        seen_commits = {}

    while (True):

        # we are done if we've found the commit
        if (commit == branch_head_commit):
            return distance;

        # check the parent commits
        parents = commit.parents

        # check if we have reached a root commit, which has no parent and thus
        # there is no common ancestor
        if (not parents):
            # if there is a dead end list, then update it
            for c in my_path:
                if not c in dead_ends:
                    dead_ends.append(c)
            return -1

        if my_path: my_path.append(commit)
        distance += 1

        if commit in seen_commits:
            (dist, parent, depth) = seen_commits[commit]

            if (depth < 0):
                # we did not analyze this path in detail. But if we've been
                # here before at a shorter distance, so there is no point in
                # analyzing it further here. Result will only be worse
                if (distance >= dist):
                    return -5 if (dist == distance) else -4
            else:
                # we did analyze this path in detail
                if (distance >= dist):
                    return -3 if (dist == distance) else -2

        if (len(parents) > 1):
            break; # leave the loop

        # if there is just one parent, then we simply follow the chain
        parent = parents[0]
        seen_commits[commit] = (distance, parent, -1)
        commit = parent
        # and continue the loop

    # we've left the loop here because we have found a merge-commit. They have
    # multiple parents, even more than just 2 are perfectly legal. We have to
    # check all paths then. There is a (design) guarantee that there are no
    # circles in the commit history. But a diamond is possible, in this case we
    # consider the shortest path.

    depth = -1;
    best_sub_path = None
    best = None
    for parent in parents:

        tmp_sub_path = []
        depth_tmp = get_ancestor_delta(
                        parent,
                        branch_head_commit,
                        distance,
                        dead_ends,
                        seen_commits,
                        tmp_sub_path)

        if (depth_tmp < 0):
            if (depth_tmp != -1):
                #    print("drop sub optimal path, {}, path {}".format(depth_tmp, len(tmp_sub_path)))
                pass
            else:
                dead_ends.append(parent)
                for c in tmp_sub_path:
                    if not c in dead_ends:
                        dead_ends.append(c)
        elif (depth < 0) or (depth > depth_tmp):
            depth = depth_tmp
            best_sub_path = tmp_sub_path
            best = parent

    if (depth < 0):
        if (depth != -1):
            # this can't happen
            raise Exception("drop optimal path")
        dead_ends.append(commit)
        return -1

    if my_path: my_path.extend(best_sub_path)

    if commit in seen_commits:
        (dist, parent, d) = seen_commits[commit]
        if (dist < distance):
            # this can't happen
            raise Exception("{} <= {},  {} vs {} ".format(dist, distance, d, depth))

    seen_commits[commit] = (distance, best, depth)

    return depth


#-------------------------------------------------------------------------------
def print_repo_info(repo, name="", level=0):

    str_indent_template = "| "

    str_indent = "{}{}".format(
                    str_indent_template * level,
                    "   " if not repo.submodules \
                        else (str_indent_template + "  ") )

    #if repo.is_dirty():
    #    print(str_indent + name + " " + get_repo_info(repo) )

    ref_branches = (
        # "integration-v1.2", "origin/integration-v1.2",
        # "trentos-1.2",      "origin/trentos-1.2",
        # "trentos",          "origin/trentos",
        # "integration",      "origin/integration",
        # "master",           "origin/master"

        "origin/integration-v1.2",
        "origin/trentos-1.2",
        "origin/trentos-integration",
        "origin/trentos",
        "origin/integration",
        "origin/master"
    )

    if name:
        print("{}+-{}".format(str_indent_template * (level-1), name))

    print("{}{}".format(str_indent, get_repo_info(repo)))

    head_branch = repo.head
    head_commit = head_branch.commit

    (is_same, is_ancestor, is_child, is_unrelated) = get_branches(repo, ref_branches)

    def print_indented(s):
        print("{}{}".format(str_indent, s))

    if is_same:
        print_indented(
            "at {}".format(", ".join(branch.name for branch in is_same)) )

    for commit, branches in is_ancestor.items():
        d = get_ancestor_delta(head_commit, commit)
        print_indented("  {}".format(get_commit_delta_str(d,branches) ))

    for commit, branches in is_child.items():
        d = -get_ancestor_delta(commit, head_commit)
        print_indented("  {}".format(get_commit_delta_str(d,branches) ))

    #if is_ancestor:
    #    print(str_indent2 + "ancestors:")
    #    for branch in is_ancestor:
    #        branch_commit = branch.commit
    #        c = head_commit
    #        cnt = 0
    #        while (c != branch_commit):
    #            c = c.parents[0]
    #            cnt += 1
    #            #print(str_indent2 + " " + c.hexsha[:8] + " " + c.summary)
    #            #branch_commit = c
    #            #if (0 == len(branch_commit.parents)): break
    #
    #
    #
    #        print(str_indent2 + "  " + branch_commit.hexsha[:8] +
    #            " [" + branch.name + "]+" + str(cnt) +
    #            #" \"" + branch_commit.summary + "\""
    #            "")

    # if is_unrelated:
    #     print(str_indent2 + "other branches:")
    #     for branch in is_unrelated:
    #         branch_commit = branch.commit
    #         print(str_indent2 + "  " + branch_commit.hexsha[:8] +
    #             " [" + branch.name + "]" +
    #             " \"" + branch_commit.summary + "\"" )

    for sm in sorted(repo.submodules, key=lambda sm: sm.name):
        print(str_indent)
        print_repo_info(sm.module(), sm.name, level+1)


#-------------------------------------------------------------------------------
def update_from_remotes(
    base_dir,
    mapping,
    versions,
    src_remote,
    remotes_to_update):

    update_jobs = []

    for subfolder, ver in versions.items():

        if not subfolder in mapping:
            print('{}'.format(subfolder))
            print('  ERROR: no repository defined')
            continue

        (src_repo, main_brnach) = mapping[subfolder]
        if ver is None:
            ver = main_brnach

        print('{}@{}'.format(subfolder, ver))

        repo_dir = os.path.join(base_dir, subfolder)
        if not os.path.exists(repo_dir):
            print('  missing SDK folder: {}'.format(repo_dir))
            continue

        repo = git.Repo(repo_dir)
        if repo.bare:
            print('  unsupported bare repo: {}'.format(repo_dir))
            continue

        # switch remotes from https to ssh
        for r in repo.remotes:
            url = r.url
            if url.startswith('https://github.com'):
                url = url.replace('https://github.com', 'ssh://git@github.com', 1)
                print('  remote \'{}\': update url to {}'.format(r.name, url))
                r.set_url(url)

        if not any(src_remote == r.name for r in repo.remotes):
            print('  remote \'{}\': missing upstream source repo'.format(src_remote))
            continue

        r = repo.remotes[src_remote]
        (pre, sep, post) = ver.partition(':')
        if sep:
            ver = post

        # update local repos from sel4 repos on github
        print('  remote \'{}\': pull from {}'.format(src_remote, r.url))
        m = r.pull(ver)
        commit_id = m[0].commit
        print('  commit {}'.format(commit_id))

        # update forked remote repos
        if (not sep) or (pre == 'b'):
            for name in remotes_to_update:
                if not any(name == r.name for r in repo.remotes):
                    print('  remote \'{}\': not set up'.format(name))
                else:
                    r = repo.remotes[name]
                    print('  remote {}: push to {}'.format(r.name, r.url))
                    r.push('{}:refs/heads/{}'.format(commit_id, ver), force=True)


#-------------------------------------------------------------------------------
def update_sel4():
    REPOS = {
        # mapping: folder -> repo
        'capdl':                       ('seL4/capdl',              'master'),
        'kernel':                      ('seL4/seL4',               'master'),
        'libs/musllibc':               ('seL4/musllibc',           'sel4'),
        'libs/projects_libs':          ('seL4/projects_libs',      'master'),
        'libs/sel4_global_components': ('seL4/global-components',  'master'),
        'libs/sel4_libs':              ('seL4/seL4_libs',          'master'),
        'libs/sel4_projects_libs':     ('seL4/seL4_projects_libs', 'master'),
        'libs/sel4_util_libs':         ('seL4/util_libs',          'master'),
        'libs/sel4runtime':            ('seL4/sel4runtime',        'master'),
        'tools/camkes':                ('seL4/camkes-tool',        'master'),
        'tools/nanopb':                ('nanopb/nanopb',           'master'),
        'tools/seL4':                  ('seL4/seL4_tools',         'master'),
        'tools/riscv-pk':              ('seL4/riscv-pk',           'master'),
        'tools/opensbi':               ('riscv/opensbi',           'master'),
    }

    VERSION_RELEASE_OLD = {
        'capdl':                       't:0.1.0',
        'kernel':                      't:11.0.0',
        'libs/musllibc':               '11.0.x-compatible',
        'libs/projects_libs':          '11.0.x-compatible',
        'libs/sel4_global_components': 'camkes-3.8.x-compatible',
        'libs/sel4_libs':              '11.0.x-compatible',
        'libs/sel4_projects_libs':     '11.0.x-compatible',
        'libs/sel4_util_libs':         '11.0.x-compatible',
        'libs/sel4runtime':            '11.0.x-compatible',
        'tools/camkes':                't:camkes-3.8.0',
        'tools/nanopb':                'c:847ac296b50936a8b13d1434080cef8edeba621c',
        'tools/seL4':                  '11.0.x-compatible',
        'tools/riscv-pk':              '11.0.x-compatible',
    }

    VERSION_RELEASE_2020_11 = {
        'capdl':                       't:0.2.0',
        'kernel':                      't:12.0.0',
        'libs/musllibc':               '12.0.x-compatible',
        'libs/projects_libs':          '12.0.x-compatible',
        'libs/sel4_global_components': 'camkes-3.9.x-compatible',
        'libs/sel4_libs':              '12.0.x-compatible',
        'libs/sel4_projects_libs':     '12.0.x-compatible',
        'libs/sel4_util_libs':         '12.0.x-compatible',
        'libs/sel4runtime':            '12.0.x-compatible',
        'tools/camkes':                't:camkes-3.9.0',
        'tools/nanopb':                'c:847ac296b50936a8b13d1434080cef8edeba621c',
        'tools/seL4':                  '12.0.x-compatible',
        'tools/riscv-pk':              '12.0.x-compatible',
    }

    VERSION_RELEASE_2021_06 = {
        'capdl':                       't:0.2.1',
        'kernel':                      't:12.1.0',
        'libs/musllibc':               '12.1.x-compatible',
        'libs/projects_libs':          '12.1.x-compatible',
        'libs/sel4_global_components': 'camkes-3.9.x-compatible',
        'libs/sel4_libs':              '12.1.x-compatible',
        'libs/sel4_projects_libs':     '12.1.x-compatible',
        'libs/sel4_util_libs':         '12.1.x-compatible',
        'libs/sel4runtime':            '12.1.x-compatible',
        'tools/camkes':                't:camkes-3.10.0',
        'tools/nanopb':                'c:847ac296b50936a8b13d1434080cef8edeba621c',
        'tools/seL4':                  '12.0.x-compatible',
        'tools/opensbi':               't:v0.9',
    }

    VERSION_CUTTING_EDGE = {
        'capdl':                       None,
        'kernel':                      None,
        'libs/musllibc':               None,
        'libs/projects_libs':          None,
        'libs/sel4_global_components': None,
        'libs/sel4_libs':              None,
        'libs/sel4_projects_libs':     None,
        'libs/sel4_util_libs':         None,
        'libs/sel4runtime':            None,
        'tools/camkes':                None,
        'tools/nanopb':                't:0.4.3',
        'tools/seL4':                  None,
        'tools/opensbi':               't:v0.9',
    }

    update_from_remotes(
        'seos_sandbox/sdk-sel4-camkes',
        REPOS,
        VERSION_CUTTING_EDGE,
        'github',
        ['origin', 'github-hc', 'axel-h'])


#-------------------------------------------------------------------------------
def update_systems():
    REPOS = [
        'src/demos/demo_hello_world',
        'src/demos/demo_i2c',
        'src/demos/demo_iot_app',
        'src/demos/demo_iot_app_imx6',
        'src/demos/demo_iot_app_rpi3',
        'src/demos/demo_raspi_ethernet',
        'src/demos/demo_tls_api',
        'src/tests/test_certparser',
        'src/tests/test_certserver',
        'src/tests/test_chanmux',
        'src/tests/test_config_server',
        'src/tests/test_crypto_api',
        'src/tests/test_cryptoserver',
        'src/tests/test_entropysource',
        'src/tests/test_filesystem',
        'src/tests/test_keystore',
        'src/tests/test_logserver',
        'src/tests/test_network_api',
        'src/tests/test_proxy_nvm',
        'src/tests/test_secure_update',
        'src/tests/test_storage_interface',
        'src/tests/test_timeserver',
        'src/tests/test_tls_api',
        'src/tests/test_tlsserver',
        'src/tests/test_uart',
        'seos_sandbox/os_core_api',
        'seos_sandbox/components/CertServer',
        'seos_sandbox/components/ChanMux',
        'seos_sandbox/components/CryptoServer',
        'seos_sandbox/components/EntropySource',
        'seos_sandbox/components/NIC_ChanMux',
        'seos_sandbox/components/NIC_Dummy',
        'seos_sandbox/components/NIC_iMX6',
        'seos_sandbox/components/NIC_RPi',
        'seos_sandbox/components/RamDisk',
        'seos_sandbox/components/RPi_SPI_Flash',
        'seos_sandbox/components/SdHostController',
        'seos_sandbox/components/Storage_ChanMux',
        'seos_sandbox/components/StorageServer',
        'seos_sandbox/components/SysLogger',
        'seos_sandbox/components/TimeServer',
        'seos_sandbox/components/TlsServer',
        'seos_sandbox/components/UART',
        'seos_sandbox/libs/chanmux',
        'seos_sandbox/libs/chanmux_nic_driver',
        'seos_sandbox/libs/lib_compiler',
        'seos_sandbox/libs/lib_debug',
        'seos_sandbox/libs/lib_host',
        'seos_sandbox/libs/lib_io',
        'seos_sandbox/libs/lib_logs',
        'seos_sandbox/libs/lib_macros',
        'seos_sandbox/libs/lib_mem',
        'seos_sandbox/libs/lib_osal',
        'seos_sandbox/libs/lib_server',
        'seos_sandbox/libs/lib_utils',
        'seos_sandbox/libs/os_cert',
        'seos_sandbox/libs/os_configuration',
        'seos_sandbox/libs/os_crypto',
        'seos_sandbox/libs/os_filesystem',
        'seos_sandbox/libs/os_keystore',
        'seos_sandbox/libs/os_logger',
        'seos_sandbox/libs/os_network_stack',
        'seos_sandbox/libs/os_tls',
        'seos_sandbox/tools/cpt',
        'seos_sandbox/tools/kpt',
        'seos_sandbox/tools/proxy',
        'seos_sandbox/tools/rdgen',
        'seos_sandbox/tools/rpi3_flasher',
    ]

    cwd = os.getcwd()
    sdk_base_dir = ''

    update_jobs = []
    for folder in REPOS:

        sdk_folder = os.path.join(sdk_base_dir, folder)
        repo = git.Repo(sdk_folder)
        assert not repo.bare
        ver = 'integration'
        remote = 'origin'
        print('{: <32} {}@{}'.format(folder, remote, ver))
        try:
            r = repo.remotes[remote]
            assert r
            r.pull(ver)
        except:
            print('FAILURE: {}'.format(folder))



#-------------------------------------------------------------------------------
def main():

    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()

    group.add_argument(
        '--update-sel4', # stored as update_sel4
        action='store_true')

    group.add_argument(
        '--update-systems', # stored as update_systems
        action='store_true')

    group.add_argument(
        '--repo-info', # stored as repo_info
        action='store_true')

    parser.set_defaults(repo_info=True)
    args = parser.parse_args()

    #print(args)

    # print("Python: " + platform.python_version())
    cwd = os.getcwd()
    print("working dir: " + cwd)

    if args.update_systems:
        update_systems()

    elif args.update_sel4:
        update_sel4()

    elif args.repo_info:
        repo = git.Repo(cwd)
        assert not repo.bare
        print_repo_info(repo)

    else:
        parser.print_help()

    # print local branches
    # heads = repo.heads
    # for h in heads: print(h.name)

    # print remote branches
    # remote_refs = repo.remote().refs
    # for ref in remote_refs: print(ref.name)


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
if __name__ == "__main__":
    # execute only if run as a script
    main()
