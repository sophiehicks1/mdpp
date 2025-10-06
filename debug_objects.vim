" Debug test to understand objects module behavior
source autoload/test/framework.vim

" Setup test buffer and examine what functions return
call test#framework#setup_buffer_from_file('tests/data/comprehensive.md')

echo "=== Buffer content around Section A ==="
for i in range(5, 10)
  echo i . ": " . getline(i)
endfor

echo "=== Testing aroundSection from line 8 ==="
call cursor(8, 1)
let result = md#objects#aroundSection()
echo "Result: " . string(result)

echo "=== Testing insideSection from line 8 ==="
call cursor(8, 1)
let result = md#objects#insideSection()
echo "Result: " . string(result)

echo "=== Testing with links buffer ==="
call test#framework#setup_buffer_from_file('tests/data/comprehensive_links.md')
for i in range(5, 10)
  echo i . ": " . getline(i)
endfor

echo "=== Testing insideLinkText from line 7 ==="
call cursor(7, 10)
let result = md#objects#insideLinkText()
echo "Result: " . string(result)

quit!