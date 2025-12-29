# Fitbud Models and Repositories UML Diagram

This document contains UML diagrams representing the models and repositories in the Fitbud application.

## Files

- `models_and_repos_diagram.puml` - PlantUML format (recommended)
- `models_and_repos_diagram.md` - Mermaid format (alternative)

## How to View the Diagrams

### PlantUML (Recommended)

1. **Online Viewer**: 
   - Visit http://www.plantuml.com/plantuml/uml/
   - Copy and paste the contents of `models_and_repos_diagram.puml`
   - Or use VS Code extension: "PlantUML"

2. **VS Code Extension**:
   - Install "PlantUML" extension by jebbs
   - Open `models_and_repos_diagram.puml`
   - Press `Alt+D` to preview

3. **Command Line**:
   ```bash
   # Install PlantUML (requires Java)
   # Download from: http://plantuml.com/download
   
   # Generate PNG
   java -jar plantuml.jar models_and_repos_diagram.puml
   ```

### Mermaid

1. **Online Viewer**: 
   - Visit https://mermaid.live/
   - Copy and paste the contents of `models_and_repos_diagram.md`

2. **VS Code Extension**:
   - Install "Markdown Preview Mermaid Support"
   - Open `models_and_repos_diagram.md`

3. **GitHub/GitLab**: 
   - Mermaid diagrams render automatically in markdown files

## Diagram Structure

### Models Package
- **Base Classes**: `FirestoreModel` (abstract base for most models)
- **Auth Models**: `AppUser`, `UserSettings`, `DeviceToken`
- **Social Models**: `BuddyRequest`, `Friendship`, `Group`, `GroupMember`, `GroupInvite`
- **Chat Models**: `Conversation`, `Message`, `ConversationParticipant`, `MessageReceipt`, `UserConversationIndex`
- **Session Models**: `Session`, `SessionParticipant`, `SessionInvite`
- **Gym Models**: `Gym`, `GymScan`
- **Subscription Models**: `Plan`, `Subscription`, `PaymentTransaction`
- **Other Models**: `Activity`, `AppNotification`, `Product`

### Repositories Package
- **Base**: `RepoBase` (base class for all repositories)
- **Container**: `Repos` (central repository provider)
- **Repositories**: 
  - `AuthRepo` - User authentication and profile
  - `BuddyRepo` - Buddy requests and friendships
  - `GroupRepo` - Groups and group management
  - `ChatRepo` - Conversations and messaging
  - `SessionRepo` - Workout sessions
  - `GymRepo` - Gyms, plans, and subscriptions
  - `ScanRepo` - Gym QR code scanning
  - `ActivityRepo` - Activity management
  - `NotificationRepo` - Notifications
  - `MediaRepo` - File uploads

## Relationships

- **Inheritance**: Models implementing `FirestoreModel` (shown with `..|>`)
- **Composition**: Repository-to-Model relationships (shown with `..>`)
- **Association**: Model-to-Model relationships (shown with `-->`)
- **Enumerations**: Status and type enums for models

## Color Coding

- **MODEL_COLOR** (#E1F5FF): Model classes
- **REPO_COLOR** (#FFF4E1): Repository classes
- **BASE_COLOR** (#E8F5E9): Base/abstract classes

## Key Relationships

1. **User-Centric**: Most models reference `AppUser` via user IDs
2. **Firestore Integration**: All models implement `FirestoreModel` for serialization
3. **Repository Pattern**: Each domain has a dedicated repository
4. **Centralized Access**: `Repos` class provides access to all repositories

