struct ExtraActivity {
    let label: String
    let abilityKeyPaths: [WritableKeyPath<SoftSkills, Int>]
}

let schoolActivities: [ExtraActivity] = [
    // Sports & Outdoors
    ExtraActivity(
        label: "Sports",
        abilityKeyPaths: [\.strength, \.courage, \.weatherEndurance]
    ),
    ExtraActivity(
        label: "Scouting",
        abilityKeyPaths: [\.stamina, \.weatherEndurance, \.navigation]
    ),
    ExtraActivity(
        label: "Hiking Club",
        abilityKeyPaths: [\.stamina, \.navigation, \.weatherEndurance]
    ),
    ExtraActivity(
        label: "Robotics",
        abilityKeyPaths: [\.tinkering, \.problemSolving, \.carefulness]
    ),

    // Arts & Media
    ExtraActivity(
        label: "Music Band",
        abilityKeyPaths: [\.creativity, \.leadershipAndFriends, \.communication]
    ),
    ExtraActivity(
        label: "Photography",
        abilityKeyPaths: [\.creativity, \.carefulness]
    ),
    ExtraActivity(
        label: "Theater Club",
        abilityKeyPaths: [\.communication, \.creativity, \.leadershipAndFriends]
    ),
    ExtraActivity(
        label: "Art Club",
        abilityKeyPaths: [\.creativity, \.carefulness]
    ),

    // Strategy & Academics
    ExtraActivity(
        label: "Chess",
        abilityKeyPaths: [\.carefulness, \.problemSolving, \.focusAndGrit]
    ),
    ExtraActivity(
        label: "Literature",
        abilityKeyPaths: [\.carefulness, \.problemSolving, \.communication]
    ),
    ExtraActivity(
        label: "Math Circle",
        abilityKeyPaths: [\.problemSolving, \.focusAndGrit]
    ),
    ExtraActivity(
        label: "Science Club",
        abilityKeyPaths: [\.problemSolving, \.carefulness, \.communication]
    ),

    // Gaming & Simulation
    ExtraActivity(
        label: "3D Simulation Gaming",
        abilityKeyPaths: [\.navigation, \.tinkering]
    ),
    ExtraActivity(
        label: "Economic Simulation Gaming",
        abilityKeyPaths: [\.problemSolving, \.communication]
    ),

    // Social & Leadership
    ExtraActivity(
        label: "Hanging out with friends",
        abilityKeyPaths: [\.communication, \.leadershipAndFriends]
    ),
    ExtraActivity(
        label: "Student Council",
        abilityKeyPaths: [\.leadershipAndFriends, \.communication, \.focusAndGrit]
    ),
    ExtraActivity(
        label: "Organizing Events",
        abilityKeyPaths: [\.leadershipAndFriends, \.communication, \.carefulness]
    ),

    // Making & Building
    ExtraActivity(
        label: "Modeling",
        abilityKeyPaths: [\.tinkering, \.creativity, \.carefulness]
    ),
    ExtraActivity(
        label: "Woodworking",
        abilityKeyPaths: [\.tinkering, \.carefulness, \.strength]
    ),
    ExtraActivity(
        label: "Coding Club",
        abilityKeyPaths: [\.problemSolving, \.focusAndGrit, \.creativity]
    ),

    // Work & Entrepreneurship
    ExtraActivity(
        label: "Mini‑job",
        abilityKeyPaths: [\.courage, \.leadershipAndFriends]
    ),
    ExtraActivity(
        label: "Pop‑up Stand",
        abilityKeyPaths: [\.entrepreneurship, \.communication, \.carefulness]
    ),
    ExtraActivity(
        label: "Volunteering Fundraising",
        abilityKeyPaths: [\.entrepreneurship, \.leadershipAndFriends, \.communication]
    ),
    ExtraActivity(
        label: "School Newspaper",
        abilityKeyPaths: [\.communication, \.carefulness, \.leadershipAndFriends]
    )
]
