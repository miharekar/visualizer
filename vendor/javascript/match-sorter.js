// match-sorter@8.0.1 downloaded from https://ga.jspm.io/npm:match-sorter@8.0.1/dist/match-sorter.esm.js

import n from"remove-accents";
/**
 * @name match-sorter
 * @license MIT license.
 * @copyright (c) 2020 Kent C. Dodds
 * @author Kent C. Dodds <me@kentcdodds.com> (https://kentcdodds.com)
 */const t={CASE_SENSITIVE_EQUAL:7,EQUAL:6,STARTS_WITH:5,WORD_STARTS_WITH:4,CONTAINS:3,ACRONYM:2,MATCHES:1,NO_MATCH:0};const e=(n,t)=>String(n.rankedValue).localeCompare(String(t.rankedValue))
/**
 * Takes an array of items and a value and returns a new array with the items that match the given value
 * @param {Array} items - the items to sort
 * @param {String} value - the value to use for ranking
 * @param {Object} options - Some options to configure the sorter
 * @return {Array} - the new sorted array
 */;function r(n,r,s){s===void 0&&(s={});const{keys:l,threshold:c=t.MATCHES,baseSort:u=e,sorter:a=n=>n.sort(((n,t)=>i(n,t,u)))}=s;const f=n.reduce(h,[]);return a(f).map((n=>{let{item:t}=n;return t}));function h(n,t,e){const i=o(t,l,r,s);const{rank:u,keyThreshold:a=c}=i;u>=a&&n.push({...i,item:t,index:e});return n}}r.rankings=t;
/**
 * Gets the highest ranking for value for the given item based on its values for the given keys
 * @param {*} item - the item to rank
 * @param {Array} keys - the keys to get values from the item for the ranking
 * @param {String} value - the value to rank against
 * @param {Object} options - options to control the ranking
 * @return {{rank: Number, keyIndex: Number, keyThreshold: Number}} - the highest ranking
 */function o(n,e,r,o){if(!e){const t=n;return{rankedValue:t,rank:s(t,r,o),keyIndex:-1,keyThreshold:o.threshold}}const l=h(n,e);return l.reduce(((n,e,l)=>{let{rank:c,rankedValue:i,keyIndex:u,keyThreshold:a}=n;let{itemValue:f,attributes:h}=e;let k=s(f,r,o);let T=i;const{minRanking:d,maxRanking:A,threshold:y}=h;k<d&&k>=t.MATCHES?k=d:k>A&&(k=A);if(k>c){c=k;u=l;a=y;T=f}return{rankedValue:T,rank:c,keyIndex:u,keyThreshold:a}}),{rankedValue:n,rank:t.NO_MATCH,keyIndex:-1,keyThreshold:o.threshold})}
/**
 * Gives a rankings score based on how well the two strings match.
 * @param {String} testString - the string to test against
 * @param {String} stringToRank - the string to rank
 * @param {Object} options - options for the match (like keepDiacritics for comparison)
 * @returns {Number} the ranking for how well stringToRank matches testString
 */function s(n,e,r){n=u(n,r);e=u(e,r);if(e.length>n.length)return t.NO_MATCH;if(n===e)return t.CASE_SENSITIVE_EQUAL;n=n.toLowerCase();e=e.toLowerCase();return n===e?t.EQUAL:n.startsWith(e)?t.STARTS_WITH:n.includes(` ${e}`)?t.WORD_STARTS_WITH:n.includes(e)?t.CONTAINS:e.length===1?t.NO_MATCH:l(n).includes(e)?t.ACRONYM:c(n,e)}
/**
 * Generates an acronym for a string.
 *
 * @param {String} string the string for which to produce the acronym
 * @returns {String} the acronym
 */function l(n){let t="";const e=n.split(" ");e.forEach((n=>{const e=n.split("-");e.forEach((n=>{t+=n.substr(0,1)}))}));return t}
/**
 * Returns a score based on how spread apart the
 * characters from the stringToRank are within the testString.
 * A number close to rankings.MATCHES represents a loose match. A number close
 * to rankings.MATCHES + 1 represents a tighter match.
 * @param {String} testString - the string to test against
 * @param {String} stringToRank - the string to rank
 * @returns {Number} the number between rankings.MATCHES and
 * rankings.MATCHES + 1 for how well stringToRank matches testString
 */function c(n,e){let r=0;let o=0;function s(n,t,e){for(let o=e,s=t.length;o<s;o++){const e=t[o];if(e===n){r+=1;return o+1}}return-1}function l(n){const o=1/n;const s=r/e.length;const l=t.MATCHES+s*o;return l}const c=s(e[0],n,0);if(c<0)return t.NO_MATCH;o=c;for(let r=1,l=e.length;r<l;r++){const l=e[r];o=s(l,n,o);const c=o>-1;if(!c)return t.NO_MATCH}const i=o-c;return l(i)}
/**
 * Sorts items that have a rank, index, and keyIndex
 * @param {Object} a - the first item to sort
 * @param {Object} b - the second item to sort
 * @return {Number} -1 if a should come first, 1 if b should come first, 0 if equal
 */function i(n,t,e){const r=-1;const o=1;const{rank:s,keyIndex:l}=n;const{rank:c,keyIndex:i}=t;const u=s===c;return u?l===i?e(n,t):l<i?r:o:s>c?r:o}
/**
 * Prepares value for comparison by stringifying it, removing diacritics (if specified)
 * @param {String} value - the value to clean
 * @param {Object} options - {keepDiacritics: whether to remove diacritics}
 * @return {String} the prepared value
 */function u(t,e){let{keepDiacritics:r}=e;t=`${t}`;r||(t=n(t));return t}
/**
 * Gets value for key in item at arbitrarily nested keypath
 * @param {Object} item - the item
 * @param {Object|Function} key - the potentially nested keypath or property callback
 * @return {Array} - an array containing the value(s) at the nested keypath
 */function a(n,t){typeof t==="object"&&(t=t.key);let e;if(typeof t==="function")e=t(n);else if(n==null)e=null;else if(Object.hasOwnProperty.call(n,t))e=n[t];else{if(t.includes("."))return f(t,n);e=null}return e==null?[]:Array.isArray(e)?e:[String(e)]}
/**
 * Given path: "foo.bar.baz"
 * And item: {foo: {bar: {baz: 'buzz'}}}
 *   -> 'buzz'
 * @param path a dot-separated set of keys
 * @param item the item to get the value from
 */function f(n,t){const e=n.split(".");let r=[t];for(let n=0,t=e.length;n<t;n++){const t=e[n];let o=[];for(let n=0,e=r.length;n<e;n++){const e=r[n];if(e!=null)if(Object.hasOwnProperty.call(e,t)){const n=e[t];n!=null&&o.push(n)}else t==="*"&&(o=o.concat(e))}r=o}if(Array.isArray(r[0])){const n=[];return n.concat(...r)}return r}
/**
 * Gets all the values for the given keys in the given item and returns an array of those values
 * @param item - the item from which the values will be retrieved
 * @param keys - the keys to use to retrieve the values
 * @return objects with {itemValue, attributes}
 */function h(n,t){const e=[];for(let r=0,o=t.length;r<o;r++){const o=t[r];const s=T(o);const l=a(n,o);for(let n=0,t=l.length;n<t;n++)e.push({itemValue:l[n],attributes:s})}return e}const k={maxRanking:Infinity,minRanking:-Infinity};
/**
 * Gets all the attributes for the given key
 * @param key - the key from which the attributes will be retrieved
 * @return object containing the key's attributes
 */function T(n){return typeof n==="string"?k:{...k,...n}}export{e as defaultBaseSortFn,r as matchSorter,t as rankings};

