import math
def sigmoid(x):
    return 1 / (1 + math.exp(-x))

def exp_decay(x, a, b):
    return a * (1 - math.exp(-b * x))

def damage_bonus(x):
    initial_bonus = 1.0
    base = (2.75 / initial_bonus) ** (1 / 17)
    return initial_bonus * base ** x

def diff_value(diff):
    mod = -0.147
    val = mod * diff
    val = -0.00038 * pow(diff,3)  - 0.03461 * diff
    return round(val,3)


# Variables for testing
ratio = 4
current_humans = 15
current_robots = 2
total_players = current_humans + current_robots
target_humans = (current_robots * ratio) - current_robots
missing_humans = target_humans - current_humans

g_f_Damage_Bonus = 1.0  # Initial damage bonus

# Parameters for the exp_decay function
a_value = 50.0  # Adjust as needed
b_value = 0.002 # Adjust as needed

# Calculate damage bonus using a sigmoid function
#sigmoid_scaling_factor = 10.0  # Adjust this value to control the scaling
#damage_bonus = sigmoid(missing_humans * sigmoid_scaling_factor)
#damage_bonus = exp_decay(missing_humans, a_value, b_value)

# Apply the damage bonus to g_f_Damage_Bonus
#g_f_Damage_Bonus *= damage_bonus + 1
# Print results
print("Total Players:", total_players)
print("Target Humans:", target_humans)
print("Missing Humans:", missing_humans)
print("Robots:", current_robots)
print("Humans:", current_humans)
print("Current Damage Bonus:", g_f_Damage_Bonus)
# Generate x values from 0 to 5

# Create a list of current_humans from 1 to 18
current_humans_list = list(range(1, 19))

# Calculate and print exp_decay for each value in current_humans_list
for current_humans in current_humans_list:
    total_players = current_humans + current_robots
    target_humans = (current_robots * ratio) - current_robots
    missing_humans = target_humans - current_humans

   # g_f_Damage_Bonus = 1.0  # Initial damage bonus

    # Calculate damage bonus using exp_decay function
##    damage_bonus = exp_decay(missing_humans, a_value, b_value)
    g_f_Damage_Bonus = damage_bonus(missing_humans)
    # Apply the damage bonus to g_f_Damage_Bonus
##    g_f_Damage_Bonus *= damage_bonus + 1

    # Print results
    print(f"Humans: {current_humans}, Current Damage Bonus: {g_f_Damage_Bonus:.2f}")