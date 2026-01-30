export const deepMerge = (obj1, obj2) => {
  const result = { ...obj1 }
  for (const key in obj2) {
    if (!Object.hasOwn(obj2, key)) continue

    if (obj2[key] instanceof Object && obj1[key] instanceof Object) {
      result[key] = deepMerge(obj1[key], obj2[key])
    } else {
      result[key] = obj2[key]
    }
  }
  return result
}

export const isObject = obj => obj && typeof obj === "object"
