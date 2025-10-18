mkdir -p tools
cat > tools/create_screen.sh <<'SH'
#!/usr/bin/env bash
# usage:
#   ./tools/create_screen.sh <module> <prefix2> <id4> [--force]
# example:
#   ./tools/create_screen.sh top to 0100
#   ./tools/create_screen.sh group_make gr 0100
#   ./tools/create_screen.sh transaction tr 0100
#   ./tools/create_screen.sh loan_book io 0100

set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <module:{top|group_make|transaction|loan_book}> <prefix2:{to|gr|tr|io}> <id4:NNNN> [--force]"
  exit 1
fi

MODULE="$1"       # top / group_make / transaction / loan_book
PREFIX="$(echo "$2" | tr '[:upper:]' '[:lower:]')"   # to / gr / tr / io
ID="$3"           # 0100 など4桁
FORCE="${4:-}"

# validate
case "$MODULE" in
  top|group_make|transaction|loan_book) ;;
  *) echo "Error: module must be one of {top|group_make|transaction|loan_book}"; exit 2 ;;
esac
case "$PREFIX" in
  to|gr|tr|io) ;;
  *) echo "Error: prefix must be one of {to|gr|tr|io}"; exit 3 ;;
esac
if ! [[ "$ID" =~ ^[0-9]{4}$ ]]; then
  echo "Error: id must be 4 digits like 0100"; exit 4
fi

NAME="${PREFIX}${ID}"                 # ex) to0100
CLASS_PREFIX="$(tr '[:lower:]' '[:upper:]' <<< ${PREFIX:0:1})${PREFIX:1}${ID}"  # ex) To0100

LIB_DIR="lib/presentation/$MODULE"
TEST_DIR="test/presentation/$MODULE"

mkdir -p "$LIB_DIR" "$TEST_DIR"

write_file () {
  local path="$1"
  local content="$2"
  if [[ -f "$path" && "$FORCE" != "--force" ]]; then
    echo "Skip (exists): $path  (use --force to overwrite)"
  else
    printf "%s" "$content" > "$path"
    echo "Wrote: $path"
  fi
}

# -------- Screen --------
SCREEN_PATH="$LIB_DIR/${NAME}Screen.dart"
read -r -d '' SCREEN_SRC <<DART
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '${NAME}Controller.dart';

class ${CLASS_PREFIX}Screen extends ConsumerWidget {
  const ${CLASS_PREFIX}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${NAME}ControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('$CLASS_PREFIX')),
      body: state.when(
        data: (v) => Center(child: Text('Loaded: \$v')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
      ),
    );
  }
}
DART
write_file "$SCREEN_PATH" "$SCREEN_SRC"

# -------- Controller --------
CONTROLLER_PATH="$LIB_DIR/${NAME}Controller.dart"
read -r -d '' CONTROLLER_SRC <<DART
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ${NAME}ControllerProvider =
    AutoDisposeAsyncNotifierProvider<${CLASS_PREFIX}Controller, String>(${CLASS_PREFIX}Controller.new);

class ${CLASS_PREFIX}Controller extends AutoDisposeAsyncNotifier<String> {
  @override
  Future<String> build() async {
    // TODO: connect application/usecases via providers
    return '$CLASS_PREFIX ready';
  }
}
DART
write_file "$CONTROLLER_PATH" "$CONTROLLER_SRC"

# -------- Tests --------
CTRL_TEST_PATH="$TEST_DIR/${NAME}ControllerTest.dart"
read -r -d '' CTRL_TEST_SRC <<DART
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyosho_app/presentation/$MODULE/${NAME}Controller.dart';

void main() {
  test('$CLASS_PREFIX controller returns data', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final result = await container.read(${NAME}ControllerProvider.future);
    expect(result, contains('ready'));
  });
}
DART
write_file "$CTRL_TEST_PATH" "$CTRL_TEST_SRC"

EVENT_TEST_PATH="$TEST_DIR/${NAME}EventTest.dart"
read -r -d '' EVENT_TEST_SRC <<DART
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('$CLASS_PREFIX event smoke', () {
    expect(1, 1);
  });
}
DART
write_file "$EVENT_TEST_PATH" "$EVENT_TEST_SRC"

echo "Done ✅  (module=$MODULE, name=$NAME, class=$CLASS_PREFIX)"
SH
chmod +x tools/create_screen.sh
