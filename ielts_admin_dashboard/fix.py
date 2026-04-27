
import os

old_block = '''async function tryGetAdminDb() {
  try {
    const { getAdminDb } = await import('@/lib/firebase-admin');
    return getAdminDb();
  } catch {
    return null;
  }
}'''

new_block = '''async function tryGetAdminDb() {
  try {
    return getAdminDb();
  } catch (err: any) {
    console.error('Failed to init admin:', err);
    return null;
  }
}'''

for root, _, files in os.walk('src/app/api'):
    for f in files:
        if f.endswith('route.ts'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            if 'import { getAdminDb }' not in content:
                content = content.replace(
                    "import { NextResponse } from 'next/server';",
                    "import { NextResponse } from 'next/server';\nimport { getAdminDb } from '@/lib/firebase-admin';"
                )
            
            content = content.replace(old_block, new_block)
            
            with open(path, 'w', encoding='utf-8') as file:
                file.write(content)
print('Done!')

