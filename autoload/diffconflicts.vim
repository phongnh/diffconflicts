" Two-way diff each side of a file with Git conflict markers
" Maintainer: Seth House <seth@eseth.com>
" License: MIT

let s:save_cpo = &cpo
set cpo&vim

function! diffconflicts#hasConflicts() abort
    return search('^<<<<<<<\s', 'nw') > 0
endfunction

function! diffconflicts#diffconfl() abort
    let l:origBuf = bufnr("%")
    let l:origFt = &filetype

    if g:diffconflicts_vcs ==# "git"
        " Obtain the git setting for the conflict style.
        let l:conflictStyle = trim(system("git config --get merge.conflictStyle"))
    else
        " Assume 2way conflict style otherwise.
        let l:conflictStyle = "diff"
    endif

    " Set up the right-hand side.
    rightb vsplit
    enew
    silent execute "read #" .. l:origBuf
    1delete _
    file RCONFL
    let &l:filetype = l:origFt
    diffthis " set foldmethod before editing
    silent keepjumps keepmarks global /^<<<<<<< /,/^=======\r\?$/delete _
    silent keepjumps keepmarks global /^>>>>>>> /delete _
    setlocal nomodifiable readonly buftype=nofile bufhidden=delete nobuflisted

    " Set up the left-hand side.
    wincmd p
    diffthis " set foldmethod before editing
    if l:conflictStyle ==? "diff3" || l:conflictStyle ==? "zdiff3"
        silent keepjumps keepmarks global /^||||||| \?/,/^>>>>>>> /delete _
    else
        silent keepjumps keepmarks global /^=======\r\?$/,/^>>>>>>> /delete _
    endif
    silent keepjumps keepmarks global /^<<<<<<< /delete _

    diffupdate
endfunction

function! s:setupBuffer(l:bufname, l:vcsAltname) abort
    if g:diffconflicts_vcs ==# "hg"
        execute "buffer" a:vcsAltname
        execute "file" a:bufname
    else
        execute "buffer" a:bufname
    endif
    setlocal nomodifiable readonly
    diffthis
endfunction

function! diffconflicts#showHistory() abort
    " Create the tab and windows.
    tabnew
    vsplit
    vsplit
    execute "normal! \<C-w>h\<C-w>h"

    " Populate each window.
    call s:setupBuffer("LOCAL", "~local.")
    wincmd l
    call s:setupBuffer("BASE", "~base.")
    wincmd l
    call s:setupBuffer("REMOTE", "~other.")

    " Put cursor back in BASE.
    wincmd h
endfunction

function! diffconflicts#checkThenShowHistory() abort
    if g:diffconflicts_vcs ==# "hg"
        let l:filecheck = 'v:val =~# "\\~base\\." || v:val =~# "\\~local\\." || v:val =~# "\\~other\\."'
    else
        let l:filecheck = 'v:val =~# "BASE" || v:val =~# "LOCAL" || v:val =~# "REMOTE"'
    endif
    let l:xs =
                \ filter(
                \   map(
                \     filter(
                \       range(1, bufnr('$')),
                \       'bufexists(v:val)'
                \     ),
                \     'bufname(v:val)'
                \   ),
                \   l:filecheck
                \ )

    if len(l:xs) < 3
        echohl WarningMsg
                    \ | echo "Missing one or more of BASE, LOCAL, REMOTE."
                    \   .. " Was Vim invoked by a Git mergetool?"
                    \ | echohl None
        return 1
    else
        call diffconflicts#showHistory()
        return 0
    endif
endfunction

function! diffconflicts#checkThenDiff() abort
    if diffconflicts#hasConflicts()
        redraw
        echohl WarningMsg
                    \ | echon "Resolve conflicts leftward then save. Use :cq to abort."
                    \ | echohl None
        return diffconflicts#diffconfl()
    else
        echohl WarningMsg | echo "No conflict markers found." | echohl None
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
