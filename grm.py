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
def get_branches(repo):

    head_commit = repo.head.commit

    is_same = list()
    is_ancestor = list()
    is_child = list()
    is_unrelated = list()

    for branches in (repo.heads, repo.remote().refs):
        for branch in branches:

            branch_commmit = branch.commit

            if (branch_commmit == head_commit):
                is_same.append(branch)

            elif repo.is_ancestor(branch_commmit, head_commit):
                is_ancestor.append(branch)

            elif repo.is_ancestor(head_commit, branch_commmit):
                is_child.append(branch)

            else:
                is_unrelated.append(branch)

    return (is_same, is_ancestor, is_child, is_unrelated)


#-------------------------------------------------------------------------------
def get_ancestor_delta(commit, branch_head):

    branch_head_commmit = branch_head.commit
    cnt = 0
    while (commit != branch_head_commmit):
        # check if we have reached the initial commit, which has no parent
        if not commit.parents: return -1 # no common ancestor
        # we don't support multiple parents, e.g. from merges
        commit = commit.parents[0]
        cnt += 1

    return cnt


#-------------------------------------------------------------------------------
def print_repo_info(repo, name="", level=0):

    str_indent_template = "| "
    str_indent  = str_indent_template * level
    str_indent2 = str_indent + (str_indent_template+"  " if repo.submodules else "   ")

    #if repo.is_dirty():
    #    print(str_indent + name + " " + get_repo_info(repo) )

    head_branch = repo.head
    head_commit = head_branch.commit

    (is_same, is_ancestor, is_child, is_unrelated) = get_branches(repo)

    ref_branches = (
        "integration",
        "origin/integration",
        "master",
        "origin/master"
    )

    found = None
    for branch in is_same:
        if branch.name in ref_branches:
            found = branch.name
            #print(str_indent2 + "[" + branch.name + "]")
            break

    str_name = "{}+-{}".format(str_indent_template * (level-1), name) if name else "(root)"
    if found:
        print(str_name + " [" + branch.name + "]")
    else:
        print(str_name)
        print(str_indent2 + get_repo_info(repo) )

        def print_delta(cnt, mode_str, branch):
                print(str_indent2 + " "*9 + \
                    str(cnt) + " commit" + ("s" if cnt > 1 else "") +
                    " " + mode_str +" [" + branch.name + "]")

        for branch in is_ancestor:
            if branch.name in ref_branches:
                cnt = get_ancestor_delta(head_commit, branch)
                print_delta(cnt, "ahead of", branch)

        for branch in is_child:
            if branch.name in ref_branches:
                cnt = get_ancestor_delta(branch.commit, head_branch)
                print_delta(cnt, "behind", branch)

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
