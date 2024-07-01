# HNG11 Task 1: User Management Script

This project is part of HNG11's DevOps track, focusing on creating a user management script for Linux environments. The script automates the creation of user accounts, assignment of groups, and password management based on input from a text file.

## Features

- **Automated User Creation**: Creates Linux user accounts with home directories.
- **Group Management**: Assigns users to primary and additional groups specified in the input file.
- **Password Generation**: Generates random passwords and securely stores them.
- **Logging**: Logs all actions and errors to `/var/log/user_management.log`.
- **Security**: Ensures secure permissions for the password file (`/var/secure/user_passwords.csv`).

## Requirements

- Linux environment (tested on Ubuntu 20.04 LTS)
- Bash shell
- `openssl` for password generation

## Usage

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/hng11-task2.git
   cd hng11-task2
   ```

2. **Prepare Input File**: Create a text file (`input_file.txt`) with each line formatted as `username; primary_group,additional_groups`.

   Example:
   ```
   user1; group1,group2
   user2; group3
   ```

3. **Run the Script**:
   ```bash
   bash create_users.sh input_file.txt
   ```

4. **Verify Output**: Check `/var/log/user_management.log` for detailed logs on user creation and group assignments.

## Example

Suppose `input_file.txt` contains:
```
destiny; sudo,dev,www-data
testuser; dev
```

Running `sudo ./create_users.sh input_file.txt` will:
- Create user `destiny` with primary group `sudo` and additional groups `dev` and `www-data`.
- Create user `testuser` with primary group `dev`.

## Contributions

Contributions are welcome! Feel free to submit issues or pull requests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
