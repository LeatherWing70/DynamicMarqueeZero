import os, pygame, time, math, subprocess, random, shlex

# 
pipe_path = "/tmp/display.pipe"
cache_path = "/home/marquee/cache"
remote_host = "pi@retropie.local"
remote_path = cache_path
current_image_path = "/home/marquee/cache/retropie.png"
user = "marquee"
sleep = 0.01


def load_image(path):
    try:
        return pygame.image.load(path).convert()
    except Exception as e:
        print(f"Error loading image: {e}")
        return None

def fade_to_image(new_image):
    new_image = pygame.transform.scale(new_image, screen.get_size())
    for alpha in range(0, 256, 52):
        new_image.set_alpha(alpha)
        screen.fill((0, 0, 0))
        screen.blit(new_image, (0, 0))
        pygame.display.flip()
        time.sleep(.01)    

def crossfade_to_image(new_image, old_image):
    new_image = pygame.transform.scale(new_image, (width, height)).convert()
    old_image = pygame.transform.scale(old_image, (width, height)).convert()
    for alpha in range(0, 256, 52):
        old_image.set_alpha(255 - alpha)
        new_image.set_alpha(alpha)
        screen.fill((0, 0, 0))
        screen.blit(old_image, (0, 0))
        screen.blit(new_image, (0, 0))
        pygame.display.flip()
        time.sleep(0.1)
    screen.blit(new_image, (0, 0))
    pygame.display.flip()

def push_transition_to_image(new_image, old_image, direction='left'):
    new_image = pygame.transform.scale(new_image, (width, height)).convert()
    old_image = pygame.transform.scale(old_image, (width, height)).convert()

    # Calculate number of frames based on screen aspect ratio
    base_frames = 20
    if aspect_ratio > 1:
        frames = max(10, int(base_frames / aspect_ratio))
    else:
        frames = max(30, int(base_frames * aspect_ratio))

    if direction in ['left', 'right']:
        step = max(1, width // frames)
        step_range = range(0, width + 1, step)
    else:
        step = max(1, height // frames)
        step_range = range(0, height + 1, step)

    for offset in step_range:
        screen.fill((0, 0, 0))
        if direction == 'left':
            screen.blit(old_image, (-offset, 0))
            screen.blit(new_image, (width - offset, 0))
        elif direction == 'right':
            screen.blit(old_image, (offset, 0))
            screen.blit(new_image, (-width + offset, 0))
        elif direction == 'up':
            screen.blit(old_image, (0, -offset))
            screen.blit(new_image, (0, height - offset))
        elif direction == 'down':
            screen.blit(old_image, (0, offset))
            screen.blit(new_image, (0, -height + offset))
        pygame.display.flip()
        time.sleep(0.01)

def pixel_dissolve(new_image, old_image):
    # Resize and prepare surfaces
    new_image = pygame.transform.scale(new_image, (width, height)).convert()
    old_image = pygame.transform.scale(old_image, (width, height)).convert()

    # Start with the old image
    screen.blit(old_image, (0, 0))
    pygame.display.flip()

    # Set block size for faster dissolve
    block_size = 3

    # Create blocks instead of per-pixel operations
    blocks = [(x, y) for x in range(0, width, block_size) for y in range(0, height, block_size)]
    random.shuffle(blocks)

    # Determine batch size based on block count
    batch_size = max(1, len(blocks) // 60)

    for i in range(0, len(blocks), batch_size):
        for x, y in blocks[i:i+batch_size]:
            block = pygame.Rect(x, y, block_size, block_size)
            screen.blit(new_image, block, block)
        pygame.display.flip()

def multi_column_vertical_alternating_wipe(new_image, old_image, columns=3):
    new_image = pygame.transform.scale(new_image, (width, height)).convert()
    old_image = pygame.transform.scale(old_image, (width, height)).convert()

    col_width = width // columns

    # Start with the old image on screen
    screen.blit(old_image, (0, 0))
    pygame.display.flip()

    # Create height ranges with alternating directions
    column_ranges = []
    for col in range(columns):
        x_start = col * col_width
        if col % 2 == 0:
            height_range = range(0, height, 10)
        else:
            height_range = range(height - 1, -1, -10)
        column_ranges.append((x_start, height_range))

    # Animate rows
    for y_offset in range(0, height, 10):
        for x_start, height_range in column_ranges:
            idx = y_offset // 10
            if idx < len(height_range):
                y = height_range[idx]
                block = pygame.Rect(x_start, y, col_width, 10)
                screen.blit(new_image, block, block)
        pygame.display.flip()
        time.sleep(sleep)

def sequential_column_wipe(new_image, old_image, columns=3):
    new_image = pygame.transform.scale(new_image, (width, height)).convert()
    old_image = pygame.transform.scale(old_image, (width, height)).convert()

    col_width = width // columns

    # Start with the old image fully visible
    screen.blit(old_image, (0, 0))
    pygame.display.flip()

    for col in range(columns):
        x_start = col * col_width
        # Alternate direction per column
        if col % 2 == 0:
            height_range = range(0, height, 10)
        else:
            height_range = range(height - 1, -1, -10)

        for y in height_range:
            block = pygame.Rect(x_start, y, col_width, 10)
            screen.blit(new_image, block, block)
            pygame.display.flip()
            time.sleep(sleep)

def sequential_row_wipe(new_image, old_image, rows=3):
    new_image = pygame.transform.scale(new_image, (width, height)).convert()
    old_image = pygame.transform.scale(old_image, (width, height)).convert()

    row_height = height // rows
    step_size = int(width/height * 10)

    # Start with the old image fully displayed
    screen.blit(old_image, (0, 0))
    pygame.display.flip()

    for row in range(rows):
        y_start = row * row_height
        if row % 2 == 0:
            width_range = range(0, width, step_size)
        else:
            width_range = range(width - 1, -1, -step_size)

        for x in width_range:
            block = pygame.Rect(x, y_start, step_size, row_height)
            screen.blit(new_image, block, block)
            pygame.display.flip()
            time.sleep(sleep)

def file_exists_locally(filename):
    return os.path.exists(os.path.join(cache_path, filename))


def download_image(local_path, remote_path):

  local_file = os.path.join(cache_path, local_path)
  # Make sure the local directory exists
  os.makedirs(os.path.dirname(local_file), exist_ok=True)
  
  # Build the sftp command script
  with open("/dev/shm/sftp.commands", "w") as f:
    f.write(f"lcd {cache_path}\n")
    f.write(f'get "{remote_path}" "{local_path}"\n')
    f.write("exit\n")

  try:
    result = subprocess.run(
      ["sftp", "-b", "/dev/shm/sftp.commands", remote_host],
      capture_output=True,
      text=True
    )
    if result.returncode != 0:
      print(f"SFTP error: {result.stderr.strip()}")
    return result.returncode == 0
  except Exception as e:
    print(f"Download failed: {e}")
    return False

def main():
    current_image_surface = None
    current_image_path = None
    num = 1  # Transition selector counter
    count = 1
  
    while True:
        with open(pipe_path, "r") as fifo:
            lines = fifo.readlines()
            if not lines:
                continue
            parts = lines[-1].strip().split("::")
            image_path = parts[0].strip()
            remote_path = parts[1].strip() if len(parts) > 1 else None
            silent = (len(parts) > 2 and parts[2].strip().lower() == "silent")
            
            if image_path and image_path != current_image_path:
                if not file_exists_locally(image_path):
                    if remote_path:
                      print(f"Downloading {image_path} via sftp...")
                      if not download_image(image_path, remote_path):
                        print("Failed to fetch image, skipping.")
                     
                full_path = os.path.join(cache_path, image_path)
                new_img = load_image(full_path)
                if new_img and not silent:
                    print(f"Displaying: {full_path} from {remote_host}:{remote_path} #{count}")
                    if not current_image_surface:
                        fade_to_image(new_img)
                    else:
                        if num == 1:
                            crossfade_to_image(new_img, current_image_surface)
                        elif num == 2:
                            push_transition_to_image(new_img, current_image_surface,"left")
                        elif num == 3:
                            push_transition_to_image(new_img, current_image_surface,"right")
                        elif num == 4:
                            push_transition_to_image(new_img, current_image_surface,"up")
                        elif num == 5:
                            push_transition_to_image(new_img, current_image_surface,"down")
                        elif num == 6:
                            pixel_dissolve(new_img, current_image_surface)
                        elif num == 7:
                            multi_column_vertical_alternating_wipe(new_img, current_image_surface, 3)
                        elif num == 8:
                            sequential_column_wipe(new_img, current_image_surface, 3)
                        elif num == 9:
                            sequential_row_wipe(new_img, current_image_surface, 3)
                            num = 0  # Reset transition counter
                        num += 1
                        count += 1
                        # Set current image references
                    current_image_surface = new_img
                    current_image_path = image_path

# Load time tasks
# Setup named pipe for inter-process communication
if not os.path.exists(pipe_path):
    os.mkfifo(pipe_path)

# Initialize full-screen Pygame window
pygame.display.init()
screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
width, height = screen.get_size()
aspect_ratio = width / height
pygame.mouse.set_visible(False)

# Initial black screen
screen.fill((0, 0, 0))
pygame.display.flip()

# Load the default image at startup
default_img = load_image(current_image_path)
if default_img:
    fade_to_image(default_img)
 
if __name__ == "__main__":
    main()
