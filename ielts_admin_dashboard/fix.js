const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    file = dir + '/' + file;
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) { 
      results = results.concat(walk(file));
    } else { 
      if (file.endsWith('route.ts')) results.push(file);
    }
  });
  return results;
}

const files = walk('src/app/api');
files.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  
  if (!content.includes('import { getAdminDb }')) {
    content = content.replace(
      'import { NextResponse } from \'next/server\';',
      'import { NextResponse } from \'next/server\';\nimport { getAdminDb } from \'@/lib/firebase-admin\';'
    );
  }

  const oldBlock = \sync function tryGetAdminDb() {
  try {
    const { getAdminDb } = await import('@/lib/firebase-admin');
    return getAdminDb();
  } catch {
    return null;
  }
}\;
  
  const newBlock = \sync function tryGetAdminDb() {
  try {
    return getAdminDb();
  } catch (err: any) {
    console.error('Failed to init admin:', err);
    return null;
  }
}\;
  
  content = content.replace(oldBlock, newBlock);
  fs.writeFileSync(file, content);
});
console.log('Replaced correctly.');
