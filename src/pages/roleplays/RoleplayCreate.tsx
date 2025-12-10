import RoleplayForm from "./RoleplayForm";
import { useNavigate } from "react-router-dom";
import { ILesson } from "../../types/interface/lesson.interface";

export default function RoleplayCreate() {
  const navigate = useNavigate();

  const handleSave = (entrance: ILesson) => {
    navigate(`/roleplay/${entrance._id}`);
  };

  return <RoleplayForm onSave={handleSave} />;
}
