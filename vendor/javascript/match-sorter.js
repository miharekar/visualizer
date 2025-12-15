// match-sorter@8.2.0 downloaded from https://ga.jspm.io/npm:match-sorter@8.2.0/dist/match-sorter.esm.js

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
 */;function r(n,r,l={}){const{keys:c,threshold:s=t.MATCHES,baseSort:u=e,sorter:a=n=>n.sort(((n,t)=>i(n,t,u)))}=l;const f=n.reduce(h,[]);return a(f).map((({item:n})=>n));function h(n,t,e){const u=o(t,c,r,l);const{rank:i,keyThreshold:a=s}=u;i>=a&&n.push({...u,item:t,index:e});return n}}r.rankings=t;
/**
 * Gets the highest ranking for value for the given item based on its values for the given keys
 * @param {*} item - the item to rank
 * @param {Array} keys - the keys to get values from the item for the ranking
 * @param {String} value - the value to rank against
 * @param {Object} options - options to control the ranking
 * @return {{rank: Number, keyIndex: Number, keyThreshold: Number}} - the highest ranking
 */function o(n,e,r,o){if(!e){const t=n;return{rankedValue:t,rank:c(t,r,o),keyIndex:-1,keyThreshold:o.threshold}}const l=k(n,e);return l.reduce((({rank:n,rankedValue:e,keyIndex:l,keyThreshold:s},{itemValue:u,attributes:i},a)=>{let f=c(u,r,o);let h=e;const{minRanking:k,maxRanking:T,threshold:d}=i;f<k&&f>=t.MATCHES?f=k:f>T&&(f=T);if(f>n){n=f;l=a;s=d;h=u}return{rankedValue:h,rank:n,keyIndex:l,keyThreshold:s}}),{rankedValue:n,rank:t.NO_MATCH,keyIndex:-1,keyThreshold:o.threshold})}function*l(n,t){let e=-1;while((e=n.indexOf(t,e+1))>-1)yield e;return-1}
/**
 * Gives a rankings score based on how well the two strings match.
 * @param {String} testString - the string to test against
 * @param {String} stringToRank - the string to rank
 * @param {Object} options - options for the match (like keepDiacritics for comparison)
 * @returns {Number} the ranking for how well stringToRank matches testString
 */function c(n,e,r){n=a(n,r);e=a(e,r);if(e.length>n.length)return t.NO_MATCH;if(n===e)return t.CASE_SENSITIVE_EQUAL;n=n.toLowerCase();e=e.toLowerCase();const o=l(n,e);const c=o.next();const i=c.value;if(n.length===e.length&&i===0)return t.EQUAL;if(i===0)return t.STARTS_WITH;let f=c;while(!f.done){if(f.value>0&&n[f.value-1]===" ")return t.WORD_STARTS_WITH;f=o.next()}return i>0?t.CONTAINS:e.length===1?t.NO_MATCH:s(n).includes(e)?t.ACRONYM:u(n,e)}
/**
 * Generates an acronym for a string.
 *
 * Segment starts ︱ at the beginning of the phrase, after a **space**, or after a **hyphen**.
 * We capture the first non-delimiter character of every segment and skip runs of delimiters.
 *
 * @example
 *   getAcronym('The Tail-spin Test')  // → "TTsT"
 *   getAcronym('edge-case')           // → "ec"
 *   getAcronym('multiple  spaces')    // → "ms"
 *
 * @param {String} string the string for which to produce the acronym
 * @returns {String} the acronym
 */function s(n){let t="";let e=" ";for(let r=0;r<n.length;r++){const o=n.charAt(r);const l=e===" "||e==="-";const c=o===" "||o==="-";l&&!c&&(t+=o);e=o}return t}
/**
 * Returns a score based on how spread apart the
 * characters from the stringToRank are within the testString.
 * A number close to rankings.MATCHES represents a loose match. A number close
 * to rankings.MATCHES + 1 represents a tighter match.
 * @param {String} testString - the string to test against
 * @param {String} stringToRank - the string to rank
 * @returns {Number} the number between rankings.MATCHES and
 * rankings.MATCHES + 1 for how well stringToRank matches testString
 */function u(n,e){let r=0;let o=0;function l(n,t,e){for(let o=e,l=t.length;o<l;o++){const e=t[o];if(e===n){r+=1;return o+1}}return-1}function c(n){const o=1/n;const l=r/e.length;const c=t.MATCHES+l*o;return c}const s=l(e[0],n,0);if(s<0)return t.NO_MATCH;o=s;for(let r=1,c=e.length;r<c;r++){const c=e[r];o=l(c,n,o);const s=o>-1;if(!s)return t.NO_MATCH}const u=o-s;return c(u)}
/**
 * Sorts items that have a rank, index, and keyIndex
 * @param {Object} a - the first item to sort
 * @param {Object} b - the second item to sort
 * @return {Number} -1 if a should come first, 1 if b should come first, 0 if equal
 */function i(n,t,e){const r=-1;const o=1;const{rank:l,keyIndex:c}=n;const{rank:s,keyIndex:u}=t;const i=l===s;return i?c===u?e(n,t):c<u?r:o:l>s?r:o}
/**
 * Prepares value for comparison by stringifying it, removing diacritics (if specified)
 * @param {String} value - the value to clean
 * @param {Object} options - {keepDiacritics: whether to remove diacritics}
 * @return {String} the prepared value
 */function a(t,{keepDiacritics:e}){t=`${t}`;e||(t=n(t));return t}
/**
 * Gets value for key in item at arbitrarily nested keypath
 * @param {Object} item - the item
 * @param {Object|Function} key - the potentially nested keypath or property callback
 * @return {Array} - an array containing the value(s) at the nested keypath
 */function f(n,t){typeof t==="object"&&(t=t.key);let e;if(typeof t==="function")e=t(n);else if(n==null)e=null;else if(Object.hasOwnProperty.call(n,t))e=n[t];else{if(t.includes("."))return h(t,n);e=null}return e==null?[]:Array.isArray(e)?e:[String(e)]}
/**
 * Given path: "foo.bar.baz"
 * And item: {foo: {bar: {baz: 'buzz'}}}
 *   -> 'buzz'
 * @param path a dot-separated set of keys
 * @param item the item to get the value from
 */function h(n,t){const e=n.split(".");let r=[t];for(let n=0,t=e.length;n<t;n++){const t=e[n];let o=[];for(let n=0,e=r.length;n<e;n++){const e=r[n];if(e!=null)if(Object.hasOwnProperty.call(e,t)){const n=e[t];n!=null&&o.push(n)}else t==="*"&&(o=o.concat(e))}r=o}if(Array.isArray(r[0])){const n=[];return n.concat(...r)}return r}
/**
 * Gets all the values for the given keys in the given item and returns an array of those values
 * @param item - the item from which the values will be retrieved
 * @param keys - the keys to use to retrieve the values
 * @return objects with {itemValue, attributes}
 */function k(n,t){const e=[];for(let r=0,o=t.length;r<o;r++){const o=t[r];const l=d(o);const c=f(n,o);for(let n=0,t=c.length;n<t;n++)e.push({itemValue:c[n],attributes:l})}return e}const T={maxRanking:Infinity,minRanking:-Infinity};
/**
 * Gets all the attributes for the given key
 * @param key - the key from which the attributes will be retrieved
 * @return object containing the key's attributes
 */function d(n){return typeof n==="string"?T:{...T,...n}}export{e as defaultBaseSortFn,f as getItemValues,r as matchSorter,t as rankings};

