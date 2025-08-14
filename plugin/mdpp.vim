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
        \ 'link-text': {
        \   'select-a-function': 'md#objects#aroundLinkText',
        \   'select-a': [],
        \   'select-i-function': 'md#objects#insideLinkText',
        \   'select-i': [],
        \ },
        \ 'link-url': {
        \   'select-a-function': 'md#objects#aroundLinkUrl',
        \   'select-a': [],
        \   'select-i-function': 'md#objects#insideLinkUrl',
        \   'select-i': [],
        \ },
        \ 'link': {
        \   'select-a-function': 'md#objects#aroundLink',
        \   'select-a': [],
        \   'select-i-function': 'md#objects#insideLink',
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
          \   'link-text': {
          \       'select-a': '<buffer> al',
          \       'select-i': '<buffer> il',
          \   },
          \   'link-url': {
          \       'select-a': '<buffer> au',
          \       'select-i': '<buffer> iu',
          \   },
          \   'link': {
          \       'select-a': '<buffer> aL',
          \       'select-i': '<buffer> iL',
          \   },
          \ })
  augroup END
endif
