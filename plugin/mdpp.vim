if exists('g:mdpp_text_objects') && g:mdpp_text_objects == 0
  " Skip text objects
else
  call textobj#user#plugin('mdpp', {
        \ 'section': {
        \   'select-a-function': 'md#objects#aroundSection',
        \   'select-a': [],
        \   'select-i-function': 'md#objects#insideSection',
        \   'select-i': [],
        \ },
        \ 'tree': {
        \   'select-a-function': 'md#objects#aroundTree',
        \   'select-a': [],
        \   'select-i-function': 'md#objects#insideTree',
        \   'select-i': [],
        \ },
        \ 'heading': {
        \   'select-a-function': 'md#objects#aroundHeading',
        \   'select-a': [],
        \   'select-i-function': 'md#objects#insideHeading',
        \   'select-i': [],
        \ },
        \})

  augroup mdpp_textobjs
    autocmd!
    autocmd FileType markdown call textobj#user#map('mdpp', {
          \   'section': {
          \     'select-a': '<buffer> as',
          \     'select-i': '<buffer> is',
          \   },
          \   'tree': {
          \       'select-a': '<buffer> at',
          \       'select-i': '<buffer> it',
          \   },
          \   'heading': {
          \       'select-a': '<buffer> ah',
          \       'select-i': '<buffer> ih',
          \   },
          \ })
  augroup END
endif
