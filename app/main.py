from app.routes import handle_get_user

def main() -> None:
    print(handle_get_user("123"))

if __name__ == "__main__":
    main()
