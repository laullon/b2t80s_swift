var oldDict = ["foo" : 1, "bar" : 2]

let newDict = Dictionary(:
    oldDict.map { key, value in (key,value) })

