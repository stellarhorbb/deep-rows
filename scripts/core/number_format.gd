class_name NumberFormat

## Formate un entier avec des espaces comme separateurs de milliers.
## Ex: 1234 -> "1 234", 1000000 -> "1 000 000".
static func with_spaces(n: int) -> String:
	var s: String = str(n)
	if n < 1000:
		return s
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = " " + result
		result = s[i] + result
		count += 1
	return result
