# Where2Aim

Where2Aim is an IOS application that help AR-15 shooters with a red dot sight to find out the best place to aim on their target for different distances and different optic riser heights. The app asks the user to input the distance to the target, the height of their optic riser, and the distance they zeroed their sight at. Then it calculates the bullet drop and shows the user where to aim on their target.

Different with other similar apps, Where2Aim tells user a more understandable aiming point instead of just showing the bullet drop in inches or MOA. For example, it will tell user to aim at the top of the target, or 1/3 up the target, instead of saying "aim 2.5 inches high". This makes it easier for shooters to quickly adjust their aim without having to do mental math or guesswork.

## User Input

- `distance_to_target`: The distance from the shooter to the target (in yards) (selectable options: 50, 100, 150, 200, 250, and 300 yards)
- `optic_riser_height`: The height of the optic riser (in inches) (this should also be a selectable option from a predefined list, common heights in the market should be included)
- `zero_distance`: The distance at which the sight is zeroed (in yards) (selectable options: 10, 15, 20, 25, and 30 yards)

## Output

- `aiming_point`: A user-friendly description of where to aim on the target (e.g., "top of the target", "1/3 up the target")
