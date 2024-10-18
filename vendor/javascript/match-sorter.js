// match-sorter@7.0.0 downloaded from https://ga.jspm.io/npm:match-sorter@7.0.0/dist/match-sorter.esm.js

import e from"remove-accents";
/**
 * @name match-sorter
 * @license MIT license.
 * @copyright (c) 2020 Kent C. Dodds
 * @author Kent C. Dodds <me@kentcdodds.com> (https://kentcdodds.com)
 */const t={CASE_SENSITIVE_EQUAL:7,EQUAL:6,STARTS_WITH:5,WORD_STARTS_WITH:4,CONTAINS:3,ACRONYM:2,MATCHES:1,NO_MATCH:0};const defaultBaseSortFn=(e,t)=>String(e.rankedValue).localeCompare(String(t.rankedValue))
/**
 * Takes an array of items and a value and returns a new array with the items that match the given value
 * @param {Array} items - the items to sort
 * @param {String} value - the value to use for ranking
 * @param {Object} options - Some options to configure the sorter
 * @return {Array} - the new sorted array
 */;function matchSorter(e,n,r){r===void 0&&(r={});const{keys:o,threshold:s=t.MATCHES,baseSort:l=defaultBaseSortFn,sorter:a=(e=>e.sort(((e,t)=>sortRankedValues(e,t,l))))}=r;const i=e.reduce(reduceItemsToRanked,[]);return a(i).map((e=>{let{item:t}=e;return t}));function reduceItemsToRanked(e,t,l){const a=getHighestRanking(t,o,n,r);const{rank:i,keyThreshold:c=s}=a;i>=c&&e.push({...a,item:t,index:l});return e}}matchSorter.rankings=t;
/**
 * Gets the highest ranking for value for the given item based on its values for the given keys
 * @param {*} item - the item to rank
 * @param {Array} keys - the keys to get values from the item for the ranking
 * @param {String} value - the value to rank against
 * @param {Object} options - options to control the ranking
 * @return {{rank: Number, keyIndex: Number, keyThreshold: Number}} - the highest ranking
 */function getHighestRanking(e,n,r,o){if(!n){const t=e;return{rankedValue:t,rank:getMatchRanking(t,r,o),keyIndex:-1,keyThreshold:o.threshold}}const s=getAllValuesToRank(e,n);return s.reduce(((e,n,s)=>{let{rank:l,rankedValue:a,keyIndex:i,keyThreshold:c}=e;let{itemValue:u,attributes:g}=n;let h=getMatchRanking(u,r,o);let k=a;const{minRanking:f,maxRanking:d,threshold:T}=g;h<f&&h>=t.MATCHES?h=f:h>d&&(h=d);if(h>l){l=h;i=s;c=T;k=u}return{rankedValue:k,rank:l,keyIndex:i,keyThreshold:c}}),{rankedValue:e,rank:t.NO_MATCH,keyIndex:-1,keyThreshold:o.threshold})}
/**
 * Gives a rankings score based on how well the two strings match.
 * @param {String} testString - the string to test against
 * @param {String} stringToRank - the string to rank
 * @param {Object} options - options for the match (like keepDiacritics for comparison)
 * @returns {Number} the ranking for how well stringToRank matches testString
 */function getMatchRanking(e,n,r){e=prepareValueForComparison(e,r);n=prepareValueForComparison(n,r);if(n.length>e.length)return t.NO_MATCH;if(e===n)return t.CASE_SENSITIVE_EQUAL;e=e.toLowerCase();n=n.toLowerCase();return e===n?t.EQUAL:e.startsWith(n)?t.STARTS_WITH:e.includes(` ${n}`)?t.WORD_STARTS_WITH:e.includes(n)?t.CONTAINS:n.length===1?t.NO_MATCH:getAcronym(e).includes(n)?t.ACRONYM:getClosenessRanking(e,n)}
/**
 * Generates an acronym for a string.
 *
 * @param {String} string the string for which to produce the acronym
 * @returns {String} the acronym
 */function getAcronym(e){let t="";const n=e.split(" ");n.forEach((e=>{const n=e.split("-");n.forEach((e=>{t+=e.substr(0,1)}))}));return t}
/**
 * Returns a score based on how spread apart the
 * characters from the stringToRank are within the testString.
 * A number close to rankings.MATCHES represents a loose match. A number close
 * to rankings.MATCHES + 1 represents a tighter match.
 * @param {String} testString - the string to test against
 * @param {String} stringToRank - the string to rank
 * @returns {Number} the number between rankings.MATCHES and
 * rankings.MATCHES + 1 for how well stringToRank matches testString
 */function getClosenessRanking(e,n){let r=0;function findMatchingCharacter(e,t,n){for(let o=n,s=t.length;o<s;o++){const n=t[o];if(n===e){r+=1;return o+1}}return-1}let o=0;function getRanking(e){const s=1/e;const l=r/n.length;const a=(n.length-o)/n.length;const i=t.MATCHES+l*s*a;return i}let s=0;let l=0;let a=0;for(let r=0,i=n.length;r<i;r++){const i=n[r];a=findMatchingCharacter(i,e,l);const c=a>-1;if(c){l=a;r===0&&(s=l)}else{if(o>0||n.length<=3)return t.NO_MATCH;o+=1}}const i=l-s;return getRanking(i)}
/**
 * Sorts items that have a rank, index, and keyIndex
 * @param {Object} a - the first item to sort
 * @param {Object} b - the second item to sort
 * @return {Number} -1 if a should come first, 1 if b should come first, 0 if equal
 */function sortRankedValues(e,t,n){const r=-1;const o=1;const{rank:s,keyIndex:l}=e;const{rank:a,keyIndex:i}=t;const c=s===a;return c?l===i?n(e,t):l<i?r:o:s>a?r:o}
/**
 * Prepares value for comparison by stringifying it, removing diacritics (if specified)
 * @param {String} value - the value to clean
 * @param {Object} options - {keepDiacritics: whether to remove diacritics}
 * @return {String} the prepared value
 */function prepareValueForComparison(t,n){let{keepDiacritics:r}=n;t=`${t}`;r||(t=e(t));return t}
/**
 * Gets value for key in item at arbitrarily nested keypath
 * @param {Object} item - the item
 * @param {Object|Function} key - the potentially nested keypath or property callback
 * @return {Array} - an array containing the value(s) at the nested keypath
 */function getItemValues(e,t){typeof t==="object"&&(t=t.key);let n;if(typeof t==="function")n=t(e);else if(e==null)n=null;else if(Object.hasOwnProperty.call(e,t))n=e[t];else{if(t.includes("."))return getNestedValues(t,e);n=null}return n==null?[]:Array.isArray(n)?n:[String(n)]}
/**
 * Given path: "foo.bar.baz"
 * And item: {foo: {bar: {baz: 'buzz'}}}
 *   -> 'buzz'
 * @param path a dot-separated set of keys
 * @param item the item to get the value from
 */function getNestedValues(e,t){const n=e.split(".");let r=[t];for(let e=0,t=n.length;e<t;e++){const t=n[e];let o=[];for(let e=0,n=r.length;e<n;e++){const n=r[e];if(n!=null)if(Object.hasOwnProperty.call(n,t)){const e=n[t];e!=null&&o.push(e)}else t==="*"&&(o=o.concat(n))}r=o}if(Array.isArray(r[0])){const e=[];return e.concat(...r)}return r}
/**
 * Gets all the values for the given keys in the given item and returns an array of those values
 * @param item - the item from which the values will be retrieved
 * @param keys - the keys to use to retrieve the values
 * @return objects with {itemValue, attributes}
 */function getAllValuesToRank(e,t){const n=[];for(let r=0,o=t.length;r<o;r++){const o=t[r];const s=getKeyAttributes(o);const l=getItemValues(e,o);for(let e=0,t=l.length;e<t;e++)n.push({itemValue:l[e],attributes:s})}return n}const n={maxRanking:Infinity,minRanking:-Infinity};
/**
 * Gets all the attributes for the given key
 * @param key - the key from which the attributes will be retrieved
 * @return object containing the key's attributes
 */function getKeyAttributes(e){return typeof e==="string"?n:{...n,...e}}export{defaultBaseSortFn,matchSorter,t as rankings};

