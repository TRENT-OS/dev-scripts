#-------------------------------------------------------------------------------
#
# Git Repo Manager
#
#
# required packages: python3-git, python3-gitdb
#
#-------------------------------------------------------------------------------

import os, sys, platform
import git

#-------------------------------------------------------------------------------
def branch_info_str(branch):
    return "[{}]@{}".format(branch.name, branch.commit.hexsha[:8])


#-------------------------------------------------------------------------------
def add_branch_to_dict(d, branch):
    commit = branch.commit
    if commit in d:
        d[commit].append(branch)
    else:
        d[commit] = [branch]

#-------------------------------------------------------------------------------
def group_branches_by_commit(branch_list):
    d = {}
    for branch in branch_list:
        add_branch_to_dict(d, branch)

    return d


#-------------------------------------------------------------------------------
def branches_info_str(branch_list):
    s = ""
    d = group_branches_by_commit(branch_list)
    for commit, branches in d.items():
        s +=  "[{}]@{}".format(
                    ", ".join(branch.name for branch in branches),
                    commit.hexsha[:8])
    return s


#-------------------------------------------------------------------------------
def get_commit_delta_str(cnt, branch_list):
    return "{} {}".format(
                "at" if (0 == cnt) \
                    else "{} commit{} {}".format(
                            abs(cnt),
                            "s" if (abs(cnt) > 1) else "",
                            "ahead of" if (cnt > 0) else "behind"),
                branches_info_str(branch_list))


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
def get_branches(repo):

    head_commit = repo.head.commit

    is_same = list()
    is_ancestor = dict()
    is_child = dict()
    is_unrelated = dict()

    for branches in (repo.heads, repo.remote().refs):
        for branch in branches:
            #print(branch.name)

            branch_commmit = branch.commit

            if (branch_commmit == head_commit):
                is_same.append(branch)

            elif repo.is_ancestor(branch_commmit, head_commit):
                add_branch_to_dict(is_ancestor, branch)

            elif repo.is_ancestor(head_commit, branch_commmit):
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

    # we've left the loop here becuase we have found a merge-commit. They have
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
            # this can't hapopen
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
    str_indent  = str_indent_template * level
    str_indent2 = str_indent + (str_indent_template+"  " if repo.submodules else "   ")

    #if repo.is_dirty():
    #    print(str_indent + name + " " + get_repo_info(repo) )

    head_branch = repo.head
    head_commit = head_branch.commit

    str_name = "(root)" if not name \
               else "{}+-{}".format(str_indent_template * (level-1), name)

    ref_branches = (
        "integration",
        "origin/integration",
        "master",
        "origin/master"
    )

    (is_same, is_ancestor, is_child, is_unrelated) = get_branches(repo)
    same_branches = get_filtered_branch_list(is_same, ref_branches)
    if same_branches:
        print("{} {}".format(
                str_name,
                branches_info_str(same_branches)))
    else:
        print(str_name)
        print(str_indent2 + get_repo_info(repo) )

        for commit, branches in is_ancestor.items():
            branch_list = get_filtered_branch_list(branches, ref_branches)
            if branch_list:
                print("{}{}{}".format(
                        str_indent2,
                        " "*9,
                        get_commit_delta_str(
                            get_ancestor_delta(head_commit, commit),
                            branch_list) ))

        for commit, branches in is_child.items():
            branch_list = get_filtered_branch_list(branches, ref_branches)
            if branch_list:
                print("{}{}{}".format(
                        str_indent2,
                        " "*9,
                        get_commit_delta_str(
                            -get_ancestor_delta(commit, head_commit),
                            branch_list) ))

    #if is_ancestor:
    #    print(str_indent2 + "ancestors:")
    #    for branch in is_ancestor:
    #        branch_commmit = branch.commit
    #        c = head_commit
    #        cnt = 0
    #        while (c != branch_commmit):
    #            c = c.parents[0]
    #            cnt += 1
    #            #print(str_indent2 + " " + c.hexsha[:8] + " " + c.summary)
    #            #branch_commmit = c
    #            #if (0 == len(branch_commmit.parents)): break
    #
    #
    #
    #        print(str_indent2 + "  " + branch_commmit.hexsha[:8] +
    #            " [" + branch.name + "]+" + str(cnt) +
    #            #" \"" + branch_commmit.summary + "\""
    #            "")

    # if is_unrelated:
    #     print(str_indent2 + "other branches:")
    #     for branch in is_unrelated:
    #         branch_commmit = branch.commit
    #         print(str_indent2 + "  " + branch_commmit.hexsha[:8] +
    #             " [" + branch.name + "]" +
    #             " \"" + branch_commmit.summary + "\"" )

    for sm in repo.submodules:
        print_repo_info(sm.module(), sm.name, level+1)




#-------------------------------------------------------------------------------
def main():
    # print("Python: " + platform.python_version())

    cwd = os.getcwd()
    print("working dir: " + cwd)

    repo = git.Repo(cwd)
    assert not repo.bare

    print_repo_info(repo)

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
