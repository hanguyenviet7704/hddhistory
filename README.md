# HDDhistory Project            
                               
## Overview                       
                            
The HDDhistory project is a comprehensive application designed to facilitate user interactions through chat and socket communication. It incorporates various modules for user authentication, chat messaging, and real-time data streaming, leveraging a robust backend architecture.
     
## Project Structure.                     
     
The project is organized into several key directories:

- **base/**: Contains foundational components such as database configurations, validation pipes, exception filters, logging services, interceptors, guards, and configuration settings.
- **modules/**: Houses the main application modules, including user authentication, chat functionalities, and socket communication.
- **utils/**: Provides utility functions and shared data transfer objects (DTOs) and interfaces used throughout the project.

## Features.    

- **User Authentication**: Supports user registration, login, and logout functionalities.
- **Chat Module**: Facilitates chat messaging between users, with a structure in place for future enhancements.
- **Socket Communication**: Implements real-time communication capabilities using WebSockets for streaming data.

## Technologies Used

- TypeScript
- NestJS
- MongoDB (with potential for MySQL and PostgreSQL)
- JWT for authentication
- Winston for logging

## Getting Started

To get started with the HDDhistory project, follow these steps:

1. **Clone the Repository**:

   ```
   git clone <repository-url>
   cd hddhistory-api
   ```

2. **Install Dependencies**:

   ```
   npm install
   ```

3. **Configure Environment Variables**:
   Create a `.env` file in the root directory and define the necessary environment variables such as `JWT_SECRET`, `MONGODB_URI`, `MAX_DEVICE` ...

4. **d**:
   Create a `google-service.json` file in the root directory and provide project firebase

5. **Run the Application**:
   ```
   npm run start:dev
   ```

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.
