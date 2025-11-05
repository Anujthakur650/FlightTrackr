# FlightyClone - Documentation Index

Welcome to the FlightyClone project! This index helps you navigate all documentation.

## 📖 Start Here

| Document | Description | Size |
|----------|-------------|------|
| **[QUICKSTART.md](QUICKSTART.md)** | 5-minute setup guide - **start here!** | 5KB |
| **[README.md](README.md)** | Project overview and main documentation | 9KB |

## 🚀 Setup & Configuration

| Document | Description | Size |
|----------|-------------|------|
| **[SETUP.md](SETUP.md)** | Detailed setup instructions for iOS app and backend | 8KB |
| **[scripts/setup.sh](scripts/setup.sh)** | Automated setup script | 3KB |

## 📋 Project Information

| Document | Description | Size |
|----------|-------------|------|
| **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** | Complete project summary with statistics | 13KB |
| **[DELIVERABLES_CHECKLIST.md](DELIVERABLES_CHECKLIST.md)** | Verification of all requirements | 11KB |
| **[CHANGELOG.md](CHANGELOG.md)** | Version history and release notes | 4KB |

## 🎨 Design & UI

| Document | Description | Size |
|----------|-------------|------|
| **[DESIGN_PREVIEWS.md](DESIGN_PREVIEWS.md)** | Visual design system and UI components | 10KB |

## 🤝 Contributing

| Document | Description | Size |
|----------|-------------|------|
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Coding standards and contribution guidelines | 8KB |
| **[LICENSE](LICENSE)** | MIT License with OpenSky attribution | 1.5KB |

## 📦 Backend Documentation

| Document | Description | Size |
|----------|-------------|------|
| **[Backend/README.md](Backend/README.md)** | Backend API documentation | 3KB |
| **[Backend/.env.example](Backend/.env.example)** | Environment configuration template | <1KB |

## 📁 Project Structure

```
FlightyClone/
├── 📱 iOS App
│   ├── FlightyClone/                 # Main app target
│   │   ├── App/                      # Entry point & environment
│   │   ├── Core/                     # Core logic (Models, Services, Storage)
│   │   ├── Features/                 # UI features (FlightUI, Notifications, Search)
│   │   ├── LiveActivitySupport/      # Live Activities
│   │   ├── Widgets/                  # Home screen widgets
│   │   └── Resources/                # Assets, strings, OpenSky TOS
│   ├── FlightyCloneTests/            # Unit tests + mocks
│   └── FlightyCloneUITests/          # UI tests
│
├── 🖥️ Backend
│   ├── src/server.js                 # Node.js + Express server
│   ├── Dockerfile                    # Container image
│   └── package.json                  # Dependencies
│
├── 🔧 Configuration
│   ├── .github/workflows/ios-ci.yml  # CI/CD pipeline
│   ├── docker-compose.yml            # Docker deployment
│   └── FlightyClone/
│       ├── project.yml               # XcodeGen config
│       ├── Package.swift             # SPM manifest
│       └── .swiftlint.yml            # Linting rules
│
└── 📚 Documentation
    ├── README.md                     # Main documentation
    ├── QUICKSTART.md                 # Quick setup guide
    ├── SETUP.md                      # Detailed setup
    ├── PROJECT_SUMMARY.md            # Project overview
    ├── DELIVERABLES_CHECKLIST.md     # Requirements verification
    ├── DESIGN_PREVIEWS.md            # Design documentation
    ├── CONTRIBUTING.md               # Contribution guidelines
    ├── CHANGELOG.md                  # Version history
    └── LICENSE                       # MIT license
```

## 🎯 Quick Links by Role

### For Developers Getting Started
1. [QUICKSTART.md](QUICKSTART.md) - 5-minute setup
2. [README.md](README.md) - Feature overview
3. [CONTRIBUTING.md](CONTRIBUTING.md) - Coding standards

### For Reviewers
1. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Complete overview
2. [DELIVERABLES_CHECKLIST.md](DELIVERABLES_CHECKLIST.md) - Requirements verification
3. [DESIGN_PREVIEWS.md](DESIGN_PREVIEWS.md) - UI documentation

### For DevOps/Deployment
1. [SETUP.md](SETUP.md) - Detailed setup
2. [Backend/README.md](Backend/README.md) - Backend configuration
3. [docker-compose.yml](docker-compose.yml) - Container deployment

### For Designers
1. [DESIGN_PREVIEWS.md](DESIGN_PREVIEWS.md) - Design system
2. [FlightyClone/FlightyClone/Resources/](FlightyClone/FlightyClone/Resources/) - Assets

## 📊 Project Statistics

- **Total Files**: 50+
- **Swift Files**: 26
- **Documentation**: 60KB+ across 8 files
- **Lines of Code**: 6,500+
- **Test Coverage**: Comprehensive unit & UI tests
- **Commits**: 5 well-documented commits

## 🎨 Key Features

- ✅ Real-time flight tracking from OpenSky Network
- ✅ Live Activities + Dynamic Island
- ✅ Home screen widgets (3 sizes)
- ✅ Push notifications
- ✅ Interactive maps and timelines
- ✅ Delay prediction heuristic
- ✅ Offline mode with caching
- ✅ Comprehensive testing
- ✅ CI/CD ready

## 🛠️ Technologies

- **iOS**: Swift 5.9+, SwiftUI, iOS 16.0+
- **Backend**: Node.js 18+, Express
- **API**: OpenSky Network REST API
- **CI/CD**: GitHub Actions
- **Deployment**: Docker + docker-compose

## 📞 Getting Help

1. Check [QUICKSTART.md](QUICKSTART.md) for common issues
2. Review [SETUP.md](SETUP.md) for detailed troubleshooting
3. Look at [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines
4. Open a GitHub issue if stuck

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

Includes attribution for OpenSky Network data usage.

---

**Ready to start?** Go to [QUICKSTART.md](QUICKSTART.md) → Run `./scripts/setup.sh` → Open Xcode → Press Cmd+R!

✈️ Happy coding!
