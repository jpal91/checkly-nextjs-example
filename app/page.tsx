// Simple sign-up form example with input validation

export default function Page() {
  return (
    <div className="flex flex-col prose lg:prose-lg bg-base-100 h-fit border border-neutral rounded-lg shadow-lg p-6">
      <h2>Sign Up For Our Awesome Service! 🎉</h2>
      <form className="group flex flex-col gap-4">
        <label className="input input-bordered flex items-center gap-2 valid-input">
          <span className="font-bold">First Name</span>
          <input type="text" className="grow" required />
        </label>
        <label className="input input-bordered flex items-center gap-2 valid-input">
          <span className="font-bold">Last Name</span>
          <input type="text" className="grow" required />
        </label>
        <label className="input input-bordered flex items-center gap-2 valid-input">
          <span className="font-bold">Email</span>
          <input type="email" className="grow" required />
        </label>
        <button className="btn btn-primary mt-4 group-has-[:invalid]:btn-disabled">
          Submit
        </button>
      </form>
    </div>
  );
}
