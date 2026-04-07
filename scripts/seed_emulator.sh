#!/usr/bin/env bash
# Start Firebase emulator and seed test data
# Usage: ./scripts/seed_emulator.sh

set -e

echo "Starting Firebase emulator..."
firebase emulators:start --only firestore,auth,functions &
EMULATOR_PID=$!
sleep 5

echo "Emulator ready at http://localhost:4000"
echo ""
echo "Test credentials:"
echo "  Parent 1: parent1@example.com / password123"
echo "  Parent 2: parent2@example.com / password123"
echo "  Child 1 PIN: 1234"
echo "  Child 2 PIN: 5678"
echo ""
echo "Emulator PID: $EMULATOR_PID"
echo "To stop: kill $EMULATOR_PID"
