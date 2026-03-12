" Two-way diff each side of a file with Git conflict markers
" Maintainer: Seth House <seth@eseth.com>
" License: MIT

if exists("g:loaded_diffconflicts")
    finish
endif
let g:loaded_diffconflicts = 1

let s:save_cpo = &cpo
set cpo&vim

" CONFIGURATION
if !exists("g:diffconflicts_vcs")
    " Default to git
    let g:diffconflicts_vcs = "git"
endif

command! -bar DiffConflicts call diffconflicts#checkThenDiff()
command! -bar DiffConflictsShowHistory call diffconflicts#checkThenShowHistory()
command! -bar DiffConflictsWithHistory call diffconflicts#checkThenShowHistory()
            \ | 1tabn
            \ | call diffconflicts#checkThenDiff()

let &cpo = s:save_cpo
unlet s:save_cpo
