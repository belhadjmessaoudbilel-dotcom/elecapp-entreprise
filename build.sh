#!/bin/bash
set -e
git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
/opt/flutter/bin/flutter pub get
/opt/flutter/bin/flutter build web --release --no-wasm-dry-run
