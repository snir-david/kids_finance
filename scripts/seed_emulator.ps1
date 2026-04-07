# Start Firebase emulator and seed test data
# Usage: .\scripts\seed_emulator.ps1

Write-Host "Starting Firebase emulator..."
Start-Process firebase -ArgumentList "emulators:start --only firestore,auth,functions" -NoNewWindow
Start-Sleep -Seconds 5

Write-Host "Emulator ready at http://localhost:4000"
Write-Host ""
Write-Host "Test credentials:"
Write-Host "  Parent 1: parent1@example.com / password123"
Write-Host "  Parent 2: parent2@example.com / password123"
Write-Host "  Child 1 PIN: 1234"
Write-Host "  Child 2 PIN: 5678"
